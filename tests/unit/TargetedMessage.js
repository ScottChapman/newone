var should = require("chai").should();
var fs = require("fs");
var targetedMessage = require("../../runtimes/nodejs/TargetedMessage.js");
var openwhisk = require("openwhisk");
var util = require("./utils/Util.js");

var message = JSON.parse(fs.readFileSync(__dirname + "/../data/targeted_message.json"));
var messageCardArray = JSON.parse(fs.readFileSync(__dirname + "/../data/targeted_message_card_array.json"));

var failed = JSON.parse(fs.readFileSync(__dirname + "/../data/failed_auth.json"));
var graphQLResp = JSON.parse(fs.readFileSync(__dirname + "/../data/graphql_response.json"));
var response = JSON.parse(fs.readFileSync(__dirname + "/../data/targeted_response.json"));


targetedMessage.setOpenwhisk(util.openWhiskStub);

process.env.__OW_ACTION_NAME = "/scottchapman@us.ibm.com_WskDeploy/WatsonWorkspace/TargetedMessage";

describe('TargetedMessage', function() {
  describe('main - TargetedMessage', function() {
    it('should return successfully send targetted message with card array', function() {
        util.reject(false);
        util.addResolveAction("WatsonWorkspace/GraphQL", graphQLResp);
        return targetedMessage.main(messageCardArray).then(resp => {
            resp.should.be.deep.equal(response);
        })
    });

    it('should return successfully send targetted message single card', function() {
        util.addResolveAction("WatsonWorkspace/GraphQL", graphQLResp);
        util.reject(false);
        return targetedMessage.main(message).then(resp => {
            resp.should.be.deep.equal(response);
        })
    });

    it('should fail on bad token', function() {
        util.addRejectAction("WatsonWorkspace/GraphQL", failed);
        util.reject(true);
        return targetedMessage.main(message).catch(resp => {
            resp.message.should.equal("Bad credentials");
        })
    });
  });
});
