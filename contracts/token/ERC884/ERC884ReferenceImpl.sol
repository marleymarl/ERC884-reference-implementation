pragma solidity ^0.4.19;

import 'zeppelin-solidity/contracts/token/ERC20/MintableToken.sol';


/**
 *  An `ERC20` compatible Token that conforms to Delaware State Senate,
 *  149th General Assembly, Senate Bill No. 69: An act to Amend Title 8
 *  of the Delaware Code Relating to the General Corporation Law.
 *
 *  Implementation Details.
 *
 *  An implementation of this Token standard SHOULD provide the following:
 *
 *  `name` - for use by wallets and exchanges.
 *  `symbol` - for use by wallets and exchanges.
 *
 *  In addition to the above the following optional `ERC20` function MUST be defined.
 *
 *  `decimals` — MUST return `0` as each Token represents a single Share and Shares are non-divisible.
 *
 *  @dev Ref https://github.com/ethereum/EIPs/pull/884
 */
contract ERC884ReferenceImpl is MintableToken {

    bytes32 constant private ZERO_BYTES = bytes32(0);
    address constant private ZERO_ADDRESS = address(0);

    uint public decimals = 0;

    mapping(address => bytes32) private verified;

    address[] private owners;

    /**
     *  This event is emitted when a verified address and associated identity hash are
     *  added to the contract.
     *  @param addr The address that was added.
     *  @param hash The identity hash associated with the address.
     *  @param sender The address that caused the address to be added.
     */
    event VerifiedAddressAdded(
        address indexed addr,
        bytes32 hash,
        address indexed sender
    );

    /**
     *  This event is emitted when a verified address its associated identity hash are
     *  removed from the contract.
     *  @param addr The address that was removed.
     *  @param sender The address that caused the address to be removed.
     */
    event VerifiedAddressRemoved(address indexed addr, address indexed sender);

    /**
     *  This event is emitted when the identity hash associated with a verified address is updated.
     *  @param addr The address whose hash was updated.
     *  @param oldHash The identity hash that was associated with the address.
     *  @param hash The hash now associated with the address.
     *  @param sender The address that caused the hash to be updated.
     */
    event VerifiedAddressUpdated(
        address indexed addr,
        bytes32 oldHash,
        bytes32 hash,
        address indexed sender
    );

    modifier isVerifiedAddress(address addr) {
        require(verified[addr] != ZERO_BYTES);
        _;
    }

    /**
     * As each token is minted it is added to the owners array.
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address _to, uint256 _amount)
        public
        onlyOwner
        canMint
        isVerifiedAddress(_to)
        returns (bool)
    {
        owners.push(_to);
        return super.mint(_to, _amount);
    }

    /**
     *  By counting the number of Token owners using `totalSupply`
     *  you can retrieve the complete list of Token owners, one at a time.
     *  It MUST throw if `index >= totalSupply()`.
     *  @param index The zero-based index of the owner.
     *  @return the address of the Token owner with the given index.
     */
    function ownerAt(uint256 index)
        public
        onlyOwner
        view
        returns (address)
    {
        require(index < totalSupply_);
        return owners[index];
    }

    /**
     *  Add a verified address, along with an associated verification hash to the contract.
     *  Upon successful addition of a verified address the contract must emit
     *  `VerifiedAddressAdded(addr, hash, msg.sender)`.
     *  It MUST throw if the supplied address or hash are zero, or if the address has already been supplied.
     *  @param addr The address of the person represented by the supplied hash.
     *  @param hash A cryptographic hash of the address owner's verified information.
     */
    function addVerified(address addr, bytes32 hash)
        public
        onlyOwner
    {
        require(addr != ZERO_ADDRESS);
        require(hash != ZERO_BYTES);
        require(verified[addr] == ZERO_BYTES);
        verified[addr] = hash;
        VerifiedAddressAdded(addr, hash, msg.sender);
    }

    /**
     *  Remove a verified address, and the associated verification hash. If the address is
     *  unknown to the contract then this does nothing. If the address is successfully removed this
     *  function must emit `VerifiedAddressRemoved(addr, msg.sender)`.
     *  It MUST throw if an attempt is made to remove a verifiedAddress that owns Tokens.
     *  @param addr The verified address to be removed.
     */
    function removeVerified(address addr)
        public
        onlyOwner
    {
        require(balances[addr] == 0);
        if (verified[addr] != ZERO_BYTES) {
            verified[addr] = ZERO_BYTES;
            VerifiedAddressRemoved(addr, msg.sender);
        }
    }

    /**
     *  Update the hash for a verified address known to the contract.
     *  Upon successful update of a verified address the contract must emit
     *  `VerifiedAddressUpdated(addr, oldHash, hash, msg.sender)`.
     *  If the hash is the same as the value already stored then
     *  no `VerifiedAddressUpdated` event is to be emitted.
     *  It MUST throw if the supplied address or hash are zero, or if the address is unknown to the contract.
     *  @param addr The verified address of the person represented by the supplied hash.
     *  @param hash A new cryptographic hash of the address owner's updated verified information.
     */
    function updateVerified(address addr, bytes32 hash)
        public
        onlyOwner
    {
        require(addr != ZERO_ADDRESS);
        require(hash != ZERO_BYTES);
        bytes32 oldHash = verified[addr];
        if (oldHash != hash) {
            verified[addr] = hash;
            VerifiedAddressUpdated(addr, oldHash, hash, msg.sender);
        }
    }

    /**
     *  Tests that the supplied address is known to the contract.
     *  @param addr The address to test.
     *  @return true if the address is known to the contract.
     */
    function isVerified(address addr)
        public
        view
        returns (bool)
    {
        return verified[addr] != ZERO_BYTES;
    }

    /**
     *  Checks that the supplied hash is associated with the given address.
     *  @param addr The address to test.
     *  @param hash The hash to test.
     *  @return true if the hash matches the one supplied with the address in `addVerified`, or `updateVerified`.
     */
    function hasHash(address addr, bytes32 hash)
        public
        view
        returns (bool)
    {
        if (addr == ZERO_ADDRESS) {
            return false;
        }
        return verified[addr] == hash;
    }

    /**
     *  The `transfer` function must not allow transfers to addresses that
     *  have not been verified and added to the contract.
     */
    function transfer(address to, uint256 value)
        public
        isVerifiedAddress(to)
        returns (bool)
    {
        return super.transfer(to, value);
    }

    /**
     *  The `transferFrom` function must not allow transfers to addresses that
     *  have not been verified and added to the contract.
     */
    function transferFrom(address from, address to, uint256 value)
        public
        isVerifiedAddress(to)
        returns (bool)
    {
        return super.transferFrom(from, to, value);
    }
}