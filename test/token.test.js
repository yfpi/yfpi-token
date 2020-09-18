const assert = require("assert");
const ganache = require("ganache-cli");
const Web3 = require("web3");
const web3 = new Web3(ganache.provider());

const contractP = require("../compile");
const contract = JSON.parse(contractP).contracts["yfpi.sol"]["YFPI"];
const abi = contract.abi;
const bytecode = contract.evm.bytecode.object;

let accounts;
let inbox;
let ac0balance;
beforeEach(async() => {
    //get list of all accounts
    // web3.eth.getAccounts().then((fechtedAccounts) => { console.log(fechtedAccounts); });

    accounts = await web3.eth.getAccounts();
    ac0balance = await web3.eth.getBalance(accounts[0]);

    //use all of those accounts to deploy contract
    inbox = await new web3.eth.Contract(abi)
        .deploy({ data: bytecode })
        .send({ from: accounts[0], gas: "2000000" });

});

describe("Inbox", () => {
    it("show account", () => {
        // console.log(accounts);
    });
    it("Show Contract", () => {
        // console.log(inbox);
    });
    it("deploys a contract", () => {
        assert.ok(inbox.options.address);
    });
    it("has total supply", async() => {
        const message = await inbox.methods.totalSupply().call();
        // console.log(message);
        assert.equal(message, "30000000000000000000000");
    });
    it("has balance", async() => {
        const message = await inbox.methods.balanceOf(accounts[0]).call({ from: accounts[0] });
        console.log(message);
        assert.equal(message, "15000000000000000000000");
    });
    it("has balance in second account", async() => {
        const message = await inbox.methods.balanceOf(accounts[1]).call({ from: accounts[0] });
        console.log(message);
        // assert.equal(message, "30000000000000000000000");
    });
    it("transfers balance in second account", async() => {
        const message1 = await inbox.methods.transfer(accounts[1], "1000000000000000000000").send({ from: accounts[0] });
        console.log(message1);
        const message2 = await inbox.methods.balanceOf(accounts[1]).call({ from: accounts[0] });
        console.log(message2);
        // assert.equal(message, "30000000000000000000000");
    });
    it("account 0 balance", async() => {
        console.log(
            await web3.eth.getBalance(accounts[0])
        );
    });
    it('allows one account to enter', async() => {

        console.log(
            await web3.eth.getBalance(accounts[0])
        );
    });

    it("isRoundOneActive", async() => {
        const message = await inbox.methods.isRoundOneActive().call();
        console.log(message);
        // assert.equal(message, "30000000000000000000000");
    });
    it("isRoundTwoActive", async() => {
        const message = await inbox.methods.isRoundTwoActive().call();
        console.log(message);
        // assert.equal(message, "30000000000000000000000");
    });

    it("activate round one", async() => {
        const message = await inbox.methods.activateRound(1).send({ from: accounts[0] });
        console.log(message);
        const message1 = await inbox.methods.isRoundOneActive().call();
        console.log(message1);
        // assert.equal(message, "30000000000000000000000");
    });
    it("activate round two", async() => {
        const message = await inbox.methods.activateRound(2).send({ from: accounts[0] });
        // console.log(message);
        const message1 = await inbox.methods.isRoundTwoActive().call();
        console.log(message1);
        // assert.equal(message, "30000000000000000000000");
    });
    it("activate round two and deactivate", async() => {
        const message = await inbox.methods.activateRound(2).send({ from: accounts[0] });
        // console.log(message);
        const message1 = await inbox.methods.isRoundTwoActive().call();
        console.log(message1);
        const message2 = await inbox.methods.activateRound(0).send({ from: accounts[0] });
        //  console.log(message2);
        const message3 = await inbox.methods.isRoundTwoActive().call();
        console.log(message3);
        // assert.equal(message, "30000000000000000000000");
    });

});