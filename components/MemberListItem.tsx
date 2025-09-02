import React from "react";
import { Pressable } from "react-native";
import { HStack } from "@/components/ui/hstack";
import { Box } from "@/components/ui/box";
import { Text } from "@/components/ui/text";
import { Avatar, AvatarFallbackText } from "@/components/ui/avatar";

interface Member {
  id: string;
  name: string;
}

interface MemberListItemProps {
  member: Member;
  onPress: (id: string) => void;
}

const MemberListItem = ({ member, onPress }: MemberListItemProps) => {
  return (
    <Pressable onPress={() => onPress(member.id)}>
      {({ pressed }) => (
        <Box
          className={`
            ${pressed ? "bg-slate-900" : "bg-slate-800"}
            p-4
            rounded-2xl
          `}
        >
          <HStack className="space-x-4 items-center">
            <Avatar className="bg-slate-700" size="md">
              <AvatarFallbackText>
                {member.name.substring(0, 2).toUpperCase()}
              </AvatarFallbackText>
            </Avatar>
            <Text className="text-xl text-white font-medium">
              {member.name}
            </Text>
          </HStack>
        </Box>
      )}
    </Pressable>
  );
};

export default MemberListItem;
