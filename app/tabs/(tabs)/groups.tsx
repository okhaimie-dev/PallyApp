import { Heading } from "@/components/ui/heading";
import { Box } from "@/components/ui/box";
import GroupCard from "@/components/GroupCard";
import { ScrollView } from "react-native";
import { useRouter } from "expo-router";

import { MOCK_GROUPS, type Group } from "@/utils/mockData";

export default function Groups() {
  const router = useRouter();

  const navigateToGroupDetail = (groupId: string) => {
    router.push({
      pathname: "/modal/groups/[id]",
      params: { id: groupId },
    });
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
