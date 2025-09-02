export interface Group {
  id: string;
  name: string;
  direction: string;
  memberCount: number;
  activity: string;
  tags: string[];
  potSize: string;
}

export const MOCK_GROUPS: Group[] = [
  {
    id: "group1",
    name: "College Degens",
    direction: "Horizontal",
    memberCount: 12,
    activity: "High",
    tags: ["Cairo", "Starknet", "Degen"],
    potSize: "$50",
  },
  {
    id: "group2",
    name: "Blockchain Wizards",
    direction: "Vertical",
    memberCount: 8,
    activity: "Medium",
    tags: ["Solidity", "Ethereum", "DAO"],
    potSize: "$30",
  },
  {
    id: "group3",
    name: "Starknet Builders",
    direction: "Horizontal",
    memberCount: 15,
    activity: "Very High",
    tags: ["Cairo", "Starknet", "Scaling"],
    potSize: "$120",
  },
  {
    id: "group4",
    name: "Wild Builders",
    direction: "Horizontal",
    memberCount: 15,
    activity: "Very High",
    tags: ["Cairo", "Starknet", "Scaling"],
    potSize: "$40",
  },
  {
    id: "group5",
    name: "Wild Chickens",
    direction: "Horizontal",
    memberCount: 15,
    activity: "Very High",
    tags: ["Cairo", "Starknet", "Scaling"],
    potSize: "$40",
  },
];
