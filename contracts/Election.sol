// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

contract Vote {
    //state Variables
    address private admin;
    uint256 private campaignId;
    address[] private votersList;
    Campaign[] private allCampaigns;


    //events
    event Voted(address indexed voter, uint256 indexed campaignId, uint256 indexed time);
    event CampaignCreated(address indexed campaignCreator, uint256 indexed campaignId, uint256 indexed time);


    struct Campaign{
        address campaignCreator;
        string name;
        string campaignDescription;
        uint256 duration;
        uint voteCount;
        address[] candidate;
    }

    struct Candidate {
        address candidateAddress;
        string candidateName;
        uint256 campaignId;
        uint256 voteAccumulated;
        address[] candidateVoters;
    }

    constructor(){
       admin = msg.sender;
    }
    

    // modifiers
    modifier onlyAdmin(){
        require(msg.sender == admin, "NOTADMIN!!");
        _;
    }

    modifier onlyVoter(){
        require(voters[msg.sender] == true, "NOT VOTER!!");
        _;
    }

    modifier votersAndAdmin(){
        require(voters[msg.sender] == true || msg.sender == admin, "NOT VOTER OR ADMIN!!");
        _;
    }

    modifier campaignIdcheck(uint256 _campaignId){
        require(campaigns[_campaignId].campaignCreator != address(0), "Inavlid Campaign Id");
        _;
    }



    //mappings
    mapping(address => bool) private voters;
    mapping(uint256 => Campaign) private campaigns;
    mapping(address => mapping(uint256 => Candidate)) candidates;
    mapping(address => mapping(uint256 => bool)) candidateRegistered;
    // mapping(uint256 => address[]) allCampaignCandidate;
    mapping(address => uint256[]) private allUserCampaings;
    mapping(uint256 => address[]) private allCampaignVoters;
    mapping(address => mapping(uint256 => bool)) private hasVoted;

    /**
     * @dev function for admin to register voters
     */
    function registerVoter(address _voter) public onlyAdmin{
        voters[_voter] = true;
        votersList.push(_voter);
    }

    /**
     * @dev function for creating campaign
     */
    function createCampaign(string memory _CampaingName, string memory _campaignDescription, uint256 _duration) votersAndAdmin public{
        bytes memory strBytes = bytes(_CampaingName);
        require(strBytes.length > 0, "Invalid CampaingName");
        require(_duration > 0, "Invalid duration");

        uint256 userCampaignId = campaignId;
        uint256 campaignDuration = block.timestamp + _duration;
        address[] memory candidate;
        campaigns[userCampaignId] = Campaign(msg.sender, _CampaingName,_campaignDescription, campaignDuration, 0, candidate);
        allUserCampaings[msg.sender].push(userCampaignId);
        campaignId ++;

        emit CampaignCreated(msg.sender, userCampaignId, block.timestamp);
    }

    function registerCandidate(address _candidate, string memory _name, uint256 _campaignId) public campaignIdcheck(_campaignId){
        require(campaigns[_campaignId].campaignCreator == msg.sender, "Not Creator");
        require(candidateRegistered[_candidate][_campaignId] == false, "Registered Candidate");
        address[] memory _voters;
        candidates[_candidate][_campaignId] = Candidate(_candidate, _name, _campaignId, 0, _voters);
        candidateRegistered[_candidate][_campaignId] = true;
        campaigns[_campaignId].candidate.push(_candidate);
        //allCampaignCandidate[_campaignId].push(_candidate);
    }
       
    /**
     * @dev function for registered voters to vote
     */
    function vote(uint256 _campaignId, address _candidate) public onlyVoter campaignIdcheck(_campaignId){
        require(hasVoted[msg.sender][_campaignId] == false, "ALREADY VOTED!!");
        require(campaigns[_campaignId].duration > block.timestamp, "Voting period is over");
        campaigns[_campaignId].voteCount += 1;
        candidates[_candidate][_campaignId].voteAccumulated +=1;
        candidates[_candidate][_campaignId].candidateVoters.push(msg.sender);
        hasVoted[msg.sender][_campaignId] = true;
        allCampaignVoters[_campaignId].push(msg.sender);

        emit Voted(msg.sender, _campaignId, block.timestamp);
    }

    /**
     * @dev function to change admin
     */
    function changeAdmin(address _newAdmin) public onlyAdmin{
        admin = _newAdmin;
    }

    /**
     * @dev function to return all voters
     */
    function getVoters() public view votersAndAdmin returns(address[] memory){
        return votersList;
    }
    
    /**
     * @dev function to get a campaign
     */
    function getCampaign(uint256 _campaignId) public view campaignIdcheck(_campaignId) votersAndAdmin returns(Campaign memory){
        return (campaigns[_campaignId]);
    }

    /**
     * @dev function to get all campaigns created by a user
     */
    function AllUserCampaigns(address _userAddress) public view votersAndAdmin returns(Campaign[] memory){
        uint256[] memory allUserCampaignIndex = allUserCampaings[_userAddress];
        Campaign[] memory userCampaign = new Campaign[](allUserCampaignIndex.length);
    
        for (uint256 i = 0; i < allUserCampaignIndex.length; i++) {
            uint256 campaignIndex = allUserCampaignIndex[i];
            require(campaignIndex < campaignId, "Invalid campaign index");
            userCampaign[i] = campaigns[campaignIndex];
        }
    
        return userCampaign; 
    }

    /**
     * @dev function to get all voters of a campaign
     */
    function AllCampaignVoters(uint256 _campaignId) public view campaignIdcheck(_campaignId) votersAndAdmin returns(address[] memory){
        return allCampaignVoters[_campaignId];
    }

    /**
     * @dev function to get all campaigns
     */
    function allCampaign() public view votersAndAdmin returns(Campaign[] memory){
        return allCampaigns;
    }

    function allCampaignCandidate(uint256 _campaignId) public view returns(address[] memory){
        return campaigns[_campaignId].candidate;
    }

    /**
     * @dev function to get vote count of a campaign
     */
    function campaignTotalVote(uint256 _campaignId) public view campaignIdcheck(_campaignId) votersAndAdmin returns(uint256){
        return campaigns[_campaignId].voteCount;
    }

    function getCandidate(uint256 _campaignId, address _candidate) public view campaignIdcheck(_campaignId) returns(Candidate memory){
        return candidates[_candidate][_campaignId];

    }

    function getCandidateVote(uint256 _campaignId, address _candidate) public view campaignIdcheck(_campaignId) returns(uint256){
        return candidates[_candidate][_campaignId].voteAccumulated;
    }

    function getCampaignWinner(uint256 _campaignId) public view returns(address winner, uint256 voteCount){
        address[] memory allCandidates = allCampaignCandidate(_campaignId);
        uint256 highestVoteCount = 0;
        
        for (uint256 i = 0; i < allCandidates.length; i++) {
            address candidateAddress = allCandidates[i];
            uint256 candidateVoteCount = candidates[candidateAddress][_campaignId].voteAccumulated;
            
            if (candidateVoteCount > highestVoteCount) {
                highestVoteCount = candidateVoteCount;
                winner = candidateAddress;
            }
        }
        
        voteCount = highestVoteCount;
    }
}
