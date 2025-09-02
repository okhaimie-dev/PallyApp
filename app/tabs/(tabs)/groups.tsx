import { Heading } from "@/components/ui/heading";
import { Box } from "@/components/ui/box";
import GroupCard from "@/components/GroupCard";
import { ScrollView } from "react-native";
import { useRouter } from "expo-router";

interface Group {
  id: string;
  name: string;
  direction: string;
  memberCount: number;
  activity: string;
  tags: string[];
  potSize: string;
}

const MOCK_GROUPS: Group[] = [
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
];

export default function Tab2() {
  const router = useRouter();

  const navigateToGroupDetail = (groupId: string) => {
    router.push(`/groups/${groupId}`);
  };

  return (
    <Box className="flex-1 bg-black pt-16 px-4">
      <Heading className="text-2xl mb-4 text-white font-bold">
        My Groups
      </Heading>

      <ScrollView showsVerticalScrollIndicator={false} className="w-full">
        <Box className="space-y-4">
          {MOCK_GROUPS.map((group) => (
            <GroupCard
              key={group.id}
              group={group}
              onPress={navigateToGroupDetail}
            />
          ))}
        </Box>
      </ScrollView>
    </Box>
  );
}
