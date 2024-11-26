// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ISign {
    struct Seed {
        uint8 v;
        bytes32 r;
        bytes32 s;
        string sSeed;
        string flag;
    }

    function checkSign(
        address _toAddress,
        string memory _funcName,
        bytes32 _messageHash,
        Seed memory _seed
    ) external;
}
