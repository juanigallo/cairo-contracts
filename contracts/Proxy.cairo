%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import (
    delegate_l1_handler,
    delegate_call,
    get_caller_address
)

#
# Storage variables
#

@storage_var
func Proxy_implementation_address() -> (implementation_address: felt):
end

@storage_var
func Proxy_admin_address() -> (admin_address: felt):
end

#
# Constructor
#

@external
func constructor{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        implementation_address: felt,
        admin_address: felt
    ):
    Proxy_implementation_address.write(implementation_address)
    Proxy_admin_address.write(admin_address)
    return ()
end

#
# Upgrade
#

@external
func upgrade{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(new_implementation: felt):
    let (caller) = get_caller_address()
    let (admin) = Proxy_admin_address.read()
    assert caller = admin
    Proxy_implementation_address.write(new_implementation)
    return ()
end

#
# Fallback functions
#

@external
@raw_input
@raw_output
func __default__{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        selector: felt,
        calldata_size: felt,
        calldata: felt*
    ) -> (
        retdata_size: felt,
        retdata: felt*
    ):
    let (address) = Proxy_implementation_address.read()

    let (retdata_size: felt, retdata: felt*) = delegate_call(
        contract_address=address,
        function_selector=selector,
        calldata_size=calldata_size,
        calldata=calldata
    )

    return (retdata_size=retdata_size, retdata=retdata)
end

@l1_handler
@raw_input
func __l1_default__{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        selector: felt,
        calldata_size: felt,
        calldata: felt*
    ):
    let (address) = Proxy_implementation_address.read()

    delegate_l1_handler(
        contract_address=address,
        function_selector=selector,
        calldata_size=calldata_size,
        calldata=calldata
    )

    return ()
end
