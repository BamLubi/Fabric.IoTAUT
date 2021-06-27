/*
 * Copyright IBM Corp. All Rights Reserved.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

'use strict';

var sha = require('js-sha256');
var asn = require('asn1.js');

var calculateBlockHash = function (header) {
    let headerAsn = asn.define('headerAsn', function () {
        this.seq().obj(
            this.key('number').int(),
            this.key('previous_hash').octstr(),
            this.key('data_hash').octstr()
        );
    });

    let output = headerAsn.encode({
        number: parseInt(header.number),
        previous_hash: Buffer.from(header.previous_hash, 'hex'),
        data_hash: Buffer.from(header.data_hash, 'hex')
    }, 'der');
    let hash = sha.sha256(output);
    return hash;
};


let header = {
    "data_hash": "dbGsTrpnpLVUeqPBA+fooW0tBGDmEyBDD/RGEifmge4=",
    "number": "13",
    "previous_hash": "7WWZaPN6gloUok46+WA0DGwTuNg3xg+bmXeSVUTHHYs="
}
var hash = calculateBlockHash(header)
console.log(hash)