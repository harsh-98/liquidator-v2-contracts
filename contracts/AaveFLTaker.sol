pragma solidity ^0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IAavePoolFlashLoan} from "./interfaces/IAavePoolFlashLoan.sol";

contract AaveFLTaker is Ownable {
    event SetAllowedFLReceiver(address indexed consumer, bool status);

    error CallerNotAllowedReceiverException();

    address public immutable aavePool;

    mapping(address => bool) public allowedFLReceiver;

    modifier onlyAllowedFLReceiver() {
        if (!allowedFLReceiver[msg.sender]) revert CallerNotAllowedReceiverException();
        _;
    }

    constructor(address _aavePool) {
        aavePool = _aavePool;
    }

    function takeFlashLoan(address asset, uint256 amount, bytes memory data) external onlyAllowedFLReceiver {
        address[] memory assets = new address[](1);
        assets[0] = asset;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;

        uint256[] memory modes = new uint256[](1);
        modes[0] = 0;

        IAavePoolFlashLoan(aavePool).flashLoan(msg.sender, assets, amounts, modes, address(this), data, 0);
    }

    function setAllowedFLReceiver(address receiver, bool status) external onlyOwner {
        if (allowedFLReceiver[receiver] == status) return;
        allowedFLReceiver[receiver] = status;
        emit SetAllowedFLReceiver(receiver, status);
    }
}
