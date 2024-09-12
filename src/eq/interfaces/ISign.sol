// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

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
        bytes32 _hashMessage,
        Seed memory _seed
    ) external;
}
