const PUBLIC_SINGER: felt252 = 0x333333;
const PUBLIC_GUARDIAN: felt252 = 0x444444;
use web3mq_aa_cario::tests::utils;
use starknet::ContractAddress;
use starknet::testing;
use starknet::contract_address_const;
use web3mq_aa_cario::TRANSACTION_VERSION;
use web3mq_aa_cario::Account;


#[derive(Drop)]
struct SignedTransactionData {
    private_key: felt252,
    public_key: felt252,
    transaction_hash: felt252,
    r: felt252,
    s: felt252
}

fn AA_CLASS_HASH() -> felt252 {
    Account::TEST_CLASS_HASH
}

fn AA_ADDRESS() -> ContractAddress {
    contract_address_const::<0x111111>()
}

fn SIGNED_TX_DATA() -> SignedTransactionData {
    SignedTransactionData {
        private_key: 1234,
        public_key: 883045738439352841478194533192765345509759306772397516907181243450667673002,
        transaction_hash: 2717105892474786771566982177444710571376803476229898722748888396642649184538,
        r: 3068558690657879390136740086327753007413919701043650133111397282816679110801,
        s: 3355728545224320878895493649495491771252432631648740019139167265522817576501
    }
}


fn deploy_account(data: Option<@SignedTransactionData>) -> ContractAddress {
    // Set the transaction version
    testing::set_version(TRANSACTION_VERSION);

    let mut calldata = array![];
    let mut _signer = PUBLIC_SINGER;
    let mut _guardian = PUBLIC_GUARDIAN;

    if data.is_some() {
        // set public key
        let _data = data.unwrap();
        _signer = *_data.public_key;

        // Set the signature and transaction hash
        let mut signature = array![];
        signature.append(*_data.r);
        signature.append(*_data.s);
        testing::set_signature(signature.span());
        testing::set_transaction_hash(*_data.transaction_hash);
    }

    // add constructor parameters to calldata
    Serde::serialize(@_signer, ref calldata);
    // Deploy the account contract
    utils::deploy(AA_CLASS_HASH(), calldata)
}

#[cfg(test)]
mod account_generic_tests {
    use web3mq_aa_cario::account::interface::AccountABIDispatcherTrait;
    use web3mq_aa_cario::account::interface::AccountABIDispatcher;
    use super::deploy_account;
    use super::PUBLIC_SINGER;
    use debug::PrintTrait;
    #[test]
    #[available_gas(5000000)]
    fn test_deploy() {
        'test deploy'.print();
        let web3mq_account = AccountABIDispatcher {
            contract_address: deploy_account(Option::None(()))
        };
        assert(web3mq_account.get_signer() == PUBLIC_SINGER, 'Should return public key');
    }
}
