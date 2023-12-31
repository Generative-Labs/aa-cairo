use starknet::account::Call;

mod account;
mod introspection;
mod tests;


const TRANSACTION_VERSION: felt252 = 1;

// 2**128 + TRANSACTION_VERSION
const QUERY_VERSION: felt252 = 340282366920938463463374607431768211457;


#[starknet::contract]
mod Account {
    use web3mq_aa_cario::account::interface::IAuth;
    use traits::TryInto;
    use traits::Into;
    use array::SpanTrait;
    use array::ArrayTrait;
    use box::BoxTrait;
    use ecdsa::check_ecdsa_signature;
    use option::OptionTrait;
    use starknet::get_tx_info;
    use starknet::library_call_syscall;
    use starknet::get_caller_address;
    use starknet::get_contract_address;
    use starknet::ContractAddress;
    use starknet::ClassHash;
    use zeroable::Zeroable;
    use starknet::contract_address::contract_address_const;
    use dict::Felt252DictTrait;
    use web3mq_aa_cario::account::interface;
    use web3mq_aa_cario::introspection::interface::ISRC5;
    use web3mq_aa_cario::introspection::interface::ISRC5Camel;
    use web3mq_aa_cario::introspection::src5::SRC5;

    use super::Call;
    use super::QUERY_VERSION;
    use super::TRANSACTION_VERSION;
    
    #[storage]
    struct Storage {
        _signer: felt252,
        _guardian: felt252,
        _plugins: LegacyMap::<ClassHash, bool>
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        _signer: felt252
    ) {
        self.initializer(_signer);
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn initializer(ref self: ContractState, _signer: felt252) {
            let mut unsafe_state = SRC5::unsafe_new_contract_state();
            SRC5::InternalImpl::register_interface(ref unsafe_state, interface::ISRC6_ID);
            self._signer.write(_signer);
        }

        fn validate_transaction(self: @ContractState) -> felt252 {
            let tx_info = get_tx_info().unbox();
            let tx_hash = tx_info.transaction_hash;
            let signature = tx_info.signature;
            assert(self._is_valid_signature(tx_hash, signature), 'Account: invalid signature');
            starknet::VALIDATED
        }

        fn _is_valid_signature(
            self: @ContractState, hash: felt252, signature: Span<felt252>
        ) -> bool {
            let valid_length = signature.len() == 2_u32;

            if valid_length {
                check_ecdsa_signature(hash, self._signer.read(), *signature.at(0_u32), *signature.at(1_u32)) || 
                check_ecdsa_signature(hash, self._guardian.read(), *signature.at(0_u32), *signature.at(1_u32))
            } else {
                false
            }
        }

        fn assert_only_self(self: @ContractState){
            let self = get_contract_address();
            let caller_address = get_caller_address();
            assert(self == caller_address, 'only self')
        }
    }

    #[external(v0)]
    impl AuthImpl of interface::IAuth<ContractState>{
        fn change_signer(ref self: ContractState,new_signer: felt252){
            self.assert_only_self();
            self._signer.write(new_signer);
        }
        fn change_guardian(ref self: ContractState,new_guardian: felt252){
            self.assert_only_self();
            self._guardian.write(new_guardian);
        }
        fn get_signer(self: @ContractState) -> felt252{
            return self._signer.read();
        }
        fn get_guardian(self: @ContractState) -> felt252{
            return self._guardian.read();
        }
    }

    #[external(v0)]
    impl PluginManagerImpl of interface::IPluginManager<ContractState>{
        fn add_plugin(ref self: ContractState, plugin: ClassHash){
            self._plugins.write(plugin, true);
        }
        fn remove_plugin(ref self: ContractState, plugin: ClassHash){
            self._plugins.write(plugin, false);
        }
        fn is_plugin(self: @ContractState, plugin: ClassHash)-> bool{
            return self._plugins.read(plugin);
        }
        fn execute_plugin(self: @ContractState, plugin: ClassHash, function_selector: felt252, calldata: Span<felt252>){
            self.assert_only_self();
            let is_plugin = self._plugins.read(plugin);
            assert(is_plugin, 'unknown plugin');
            library_call_syscall(plugin, function_selector, calldata);
        }
    }

    #[external(v0)]
    impl SRC6Impl of interface::ISRC6<ContractState> {
        fn __execute__(self: @ContractState, mut calls: Array<Call>) -> Array<Span<felt252>> {
            // Avoid calls from other contracts
            // https://github.com/OpenZeppelin/cairo-contracts/issues/344
            let sender = get_caller_address();
            assert(sender.is_zero(), 'Account: invalid caller');

            // Check tx version
            let tx_info = get_tx_info().unbox();
            let version = tx_info.version;
            if version != TRANSACTION_VERSION {
                assert(version == QUERY_VERSION, 'Account: invalid tx version');
            }

            _execute_calls(self, calls)
        }

        fn __validate__(self: @ContractState, mut calls: Array<Call>) -> felt252 {
            self.validate_transaction()
        }

        fn is_valid_signature(
            self: @ContractState, hash: felt252, signature: Array<felt252>
        ) -> felt252 {
            if self._is_valid_signature(hash, signature.span()) {
                starknet::VALIDATED
            } else {
                0
            }
        }
    }

    #[external(v0)]
    impl SRC6CamelOnlyImpl of interface::ISRC6CamelOnly<ContractState> {
        fn isValidSignature(
            self: @ContractState, hash: felt252, signature: Array<felt252>
        ) -> felt252 {
            SRC6Impl::is_valid_signature(self, hash, signature)
        }
    }

    #[external(v0)]
    impl DeclarerImpl of interface::IDeclarer<ContractState> {
        fn __validate_declare__(self: @ContractState, class_hash: felt252) -> felt252 {
            self.validate_transaction()
        }
    }

    #[external(v0)]
    impl SRC5Impl of ISRC5<ContractState> {
        fn supports_interface(self: @ContractState, interface_id: felt252) -> bool {
            let unsafe_state = SRC5::unsafe_new_contract_state();
            SRC5::SRC5Impl::supports_interface(@unsafe_state, interface_id)
        }
    }

    #[external(v0)]
    impl SRC5CamelImpl of ISRC5Camel<ContractState> {
        fn supportsInterface(self: @ContractState, interfaceId: felt252) -> bool {
            let unsafe_state = SRC5::unsafe_new_contract_state();
            SRC5::SRC5CamelImpl::supportsInterface(@unsafe_state, interfaceId)
        }
    }



    #[internal]
    fn _execute_calls(self: @ContractState, mut calls: Array<Call>) -> Array<Span<felt252>> {
        let mut res = ArrayTrait::new();
        loop {
            match calls.pop_front() {
                Option::Some(call) => {
                    let _res = _execute_single_call(self, call);
                    res.append(_res);
                },
                Option::None(_) => {
                    break ();
                },
            };
        };
        res
    }

    #[internal]
    fn _execute_single_call(self: @ContractState, call: Call) -> Span<felt252> {
        let Call{to, selector, calldata } = call;
        starknet::call_contract_syscall(to, selector, calldata.span()).unwrap()
    }
}