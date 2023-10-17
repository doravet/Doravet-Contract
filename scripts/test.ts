import { ethers } from "hardhat";

async function main() {
  const [deployer, member1, member2, member3, member4, member5, member6, member7] = await ethers.getSigners();

  const Vote = await ethers.deployContract("Vote");

  await Vote.waitForDeployment();

  console.log(`Vote   deployed to ${Vote.target}` );


  ///-----------------interact----------//
  const voteContract = await ethers.getContractAt("Vote", Vote.target);
  //console.log("voteContract", voteContract);


  //join
  const join = await voteContract.connect(member1).join("hizick27@mail", "isaac", "hizick", "isaac coporation");
  await join.wait();
  console.log("join", join);

  //create campaign
  const startTime = 60 * 60 * 24 * 1; // days
  const endtime = 60 * 60 * 24 * 5; //5days
  const cr8campaign = await voteContract.connect(member1).createCampaign("Campaign1", "first campaign", startTime, endtime);
                      await voteContract.connect(member1).createCampaign("Campaign2", "second campaign", startTime, endtime);
  console.log("cr8campaign", cr8campaign);


  //add candidates
  const addcandidates = await voteContract.connect(member1).registerCandidate(member2.address, "Candidate2", 0);
                        await voteContract.connect(member1).registerCandidate(member3.address, "Candidate3", 0);
  console.log("addcandidates", addcandidates);

  //register voters
  const allvoters = [member1.address, member2.address, member3.address, member4.address, member5.address, member6.address, member7.address]
  const regvoters = await voteContract.connect(member1).registerVoter(allvoters, 0);

  //vote
  const vote = await voteContract.connect(member2).vote(0, member2.address);
  await voteContract.connect(member3).vote(0, member2.address);
  await voteContract.connect(member5).vote(0, member2.address);
  await voteContract.connect(member4).vote(0, member3.address);
  console.log("vote", vote);

//get Voters
  const voters = await voteContract.getVoters(0);
  console.log("voters", voters);

//get campaingn voters
const campaignVoters = await voteContract.AllCampaignVoters(0);
console.log("campaignVoters", campaignVoters);

// all Campaign Candidate
const campaignCandidate = await voteContract.allCampaignCandidate(0);
console.log("campaignCandidate", campaignCandidate);

// all Campaign
const allCampaign = await voteContract.allCampaign();
console.log("allCampaign", allCampaign);

// get Campaign
const campaign = await voteContract.getCampaign(0);
console.log("campaign", campaign);

// campaign Total Vote
const campaignTotalVote = await voteContract.campaignTotalVote(0);
console.log("campaignTotalVote", campaignTotalVote);

// get Campaign Winner
const campaignWinner = await voteContract.getCampaignWinner(0);
console.log("campaignWinner", campaignWinner);








}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
