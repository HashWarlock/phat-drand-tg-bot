// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./PhatRollupAnchor.sol";

contract TestLensApiConsumerContract is PhatRollupAnchor, Ownable {
    event ResponseReceived(uint reqId, string pair, uint256 value);
    event DrandRandomnessReceived(uint reqid, string drandRandomness);
    event ErrorReceived(uint reqId, string pair, uint256 errno);

    uint constant TYPE_RESPONSE = 0;
    uint constant TYPE_ERROR = 2;

    mapping(uint => string) requests;
    mapping(uint => string) randomness;
    uint nextRequest = 1;

    constructor(address phatAttestor) {
        _grantRole(PhatRollupAnchor.ATTESTOR_ROLE, phatAttestor);
    }

    function setAttestor(address phatAttestor) public {
        _grantRole(PhatRollupAnchor.ATTESTOR_ROLE, phatAttestor);
    }

    function request(string calldata profileId) public {
        // assemble the request
        uint id = nextRequest;
        requests[id] = profileId;
        _pushMessage(abi.encode(id, profileId));
        nextRequest += 1;
    }

    // For test
    function malformedRequest(bytes calldata malformedData) public {
        uint id = nextRequest;
        requests[id] = "malformed_req";
        _pushMessage(malformedData);
        nextRequest += 1;
    }

    function _onMessageReceived(bytes calldata action) internal override {
        //require(action.length == 32 * 3, "cannot parse action");
        (uint respType, uint id, uint data, string memory drandRandomness) = abi.decode(
            action,
            (uint, uint, uint, string)
        );
        if (respType == TYPE_RESPONSE) {
            randomness[data] = drandRandomness;
            emit ResponseReceived(id, requests[id], data);
            emit DrandRandomnessReceived(id, drandRandomness);
            delete requests[id];
        } else if (respType == TYPE_ERROR) {
            emit ErrorReceived(id, requests[id], data);
            delete requests[id];
        }
    }
}
