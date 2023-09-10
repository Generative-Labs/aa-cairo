use array::ArrayTrait;
use array::SpanTrait;
use starknet::account::Call;
use starknet::ContractAddress;
use starknet::ClassHash;

const ISRC6_ID: felt252 = 0x2ceccef7f994940b3962a6c67e0ba4fcd37df7d131417c604f91e03caecc1cd;

#[starknet::interface]
trait ISRC6<TState> {
    fn __execute__(self: @TState, calls: Array<Call>) -> Array<Span<felt252>>;
    fn __validate__(self: @TState, calls: Array<Call>) -> felt252;
    fn is_valid_signature(self: @TState, hash: felt252, signature: Array<felt252>) -> felt252;
}

#[starknet::interface]
trait ISRC6CamelOnly<TState> {
    fn isValidSignature(self: @TState, hash: felt252, signature: Array<felt252>) -> felt252;
}

#[starknet::interface]
trait IDeclarer<TState> {
    fn __validate_declare__(self: @TState, class_hash: felt252) -> felt252;
}

#[starknet::interface]
trait AccountABI<TState> {
    fn __execute__(self: @TState, calls: Array<Call>) -> Array<Span<felt252>>;
    fn __validate__(self: @TState, calls: Array<Call>) -> felt252;
    fn __validate_declare__(self: @TState, class_hash: felt252) -> felt252;
    fn __validate_deploy__(
        self: @TState, class_hash: felt252, contract_address_salt: felt252, _public_key: felt252
    ) -> felt252;
    fn change_signer(ref self: TState, new_signer: felt252);
    fn get_signer(self: @TState) -> felt252;
    fn change_guardian(ref self: TState, new_guardian: felt252);
    fn get_guardian(self: @TState) -> felt252;
    fn is_valid_signature(self: @TState, hash: felt252, signature: Array<felt252>) -> felt252;
    fn supports_interface(self: @TState, interface_id: felt252) -> bool;
}

// Entry points case-convention is enforced by the protocol
#[starknet::interface]
trait AccountCamelABI<TState> {
    fn __execute__(self: @TState, calls: Array<Call>) -> Array<Span<felt252>>;
    fn __validate__(self: @TState, calls: Array<Call>) -> felt252;
    fn __validate_declare__(self: @TState, classHash: felt252) -> felt252;
    fn __validate_deploy__(
        self: @TState, classHash: felt252, contractAddressSalt: felt252, _publicKey: felt252
    ) -> felt252;
    fn changeSigner(ref self: TState, new_signer: felt252);
    fn getSigner(self: @TState) -> felt252;
    fn changeGuardian(ref self: TState, new_guardian: felt252);
    fn getGuardian(self: @TState) -> felt252;
    fn isValidSignature(self: @TState, hash: felt252, signature: Array<felt252>) -> felt252;
    fn supportsInterface(self: @TState, interfaceId: felt252) -> bool;
}

#[starknet::interface]
trait IAuth<TState>{
    fn change_signer(ref self: TState, new_signer: felt252);
    fn get_signer(self: @TState) -> felt252;
    fn change_guardian(ref self: TState, new_guardian: felt252);
    fn get_guardian(self: @TState) -> felt252;
}

#[starknet::interface]
trait IPluginManager<TState>{
    fn add_plugin(ref self: TState, plugin: ClassHash);
    fn remove_plugin(ref self: TState, plugin: ClassHash);
    fn is_plugin(self: @TState, plugin: ClassHash) -> bool;
    fn execute_plugin(self: @TState, plugin: ClassHash, function_selector: felt252, calldata: Span<felt252>);
}

#[starknet::interface]
trait ISessionKey<TState> {
    fn set_session(ref self: TState, : ) -> ;
    fn check_session(self: @TState, session: felt252);
}