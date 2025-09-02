import React from "react";
import { Box } from "@/components/ui/box";
import { Heading } from "@/components/ui/heading";
import { Text } from "@/components/ui/text";
import { VStack } from "@/components/ui/vstack";
import { useLocalSearchParams } from "expo-router";
import { ScrollView } from "react-native";
import MemberListItem from "@/components/MemberListItem";
import { MOCK_GROUPS } from "@/utils/mockData";

interface Member {
  id: string;
  name: string;
}

const MOCK_MEMBERS: Member[] = [
  { id: "member1", name: "Alice Johnson" },
  { id: "member2", name: "Bob Smith" },
  { id: "member3", name: "Sparis" },
  { id: "member4", name: "Memburs" },
  { id: "member5", name: "Charlie Brown" },
  { id: "member6", name: "Menels" },
];

export default function GroupDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();

  const handlePressMember = (memberId: string) => {
    console.log(`Tapping on member: ${memberId}`);
  };

  // Find the group from MOCK_GROUPS
  const group = MOCK_GROUPS.find((g) => g.id === id);

  // If group is not found, show error state
  if (!group) {
    return (
      <Box className="flex-1 bg-black pt-16 px-4">
        <Text className="text-white">Group not found</Text>
      </Box>
    );
  }

  return (
    <Box className="flex-1 bg-black pt-16 px-4">
      <Heading className="text-4xl mb-2 text-white font-bold">
        {group.name}
      </Heading>

      <Text className="text-2xl mb-8 text-gray-400">
        The Pot: {group.potSize}
      </Text>

      <ScrollView showsVerticalScrollIndicator={false} className="w-full">
        <VStack className="space-y-4">
          {MOCK_MEMBERS.map((member) => (
            <MemberListItem
              key={member.id}
              member={member}
              onPress={handlePressMember}
            />
          ))}
        </VStack>
      </ScrollView>
    </Box>
  );
}
