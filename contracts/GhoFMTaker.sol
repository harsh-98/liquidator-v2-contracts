pragma solidity ^0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IGhoFlashMinter} from "./interfaces/IGhoFlashMinter.sol";

contract GhoFMTaker is Ownable {
    event SetAllowedFMReceiver(address indexed consumer, bool status);

    error CallerNotAllowedReceiverException();

    address public immutable ghoFlashMinter;
    address public immutable gho;

    mapping(address => bool) public allowedFMReceiver;

    modifier onlyAllowedFMReceiver() {
        if (!allowedFMReceiver[msg.sender]) revert CallerNotAllowedReceiverException();
        _;
    }

    constructor(address _ghoFlashMinter, address _gho) {
        ghoFlashMinter = _ghoFlashMinter;
        gho = _gho;
    }

    function takeFlashMint(uint256 amount, bytes memory data) external onlyAllowedFMReceiver {
        IGhoFlashMinter(ghoFlashMinter).flashLoan(msg.sender, gho, amount, data);
    }

    function setAllowedFMReceiver(address receiver, bool status) external onlyOwner {
        if (allowedFMReceiver[receiver] == status) return;
        allowedFMReceiver[receiver] = status;
        emit SetAllowedFMReceiver(receiver, status);
    }
}
