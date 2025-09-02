import React from "react";
import { Pressable } from "react-native";

import { VStack } from "@/components/ui/vstack";
import { HStack } from "@/components/ui/hstack";
import { Box } from "@/components/ui/box";
import { Text } from "@/components/ui/text";
import {
  Avatar,
  AvatarFallbackText,
  AvatarImage,
} from "@/components/ui/avatar";
import { Icon, GlobeIcon } from "@/components/ui/icon";

interface Group {
  id: string;
  name: string;
  direction?: string;
  memberCount: number;
  activity: string;
  tags?: string[];
}

interface GroupCardProps {
  group: Group;
  onPress: (id: string) => void;
}

const GroupCard: React.FC<GroupCardProps> = ({ group, onPress }) => {
  return (
    <Pressable onPress={() => onPress(group.id)}>
      {({ pressed }) => (
        <Box
          className={`${
            pressed ? "bg-background-800" : "bg-background-900"
          } p-4 rounded-lg mb-4 border border-background-700`}
        >
          <HStack className="space-x-4 items-center">
            {/* Left Section: Avatar */}
            <Box className="w-16 h-16 bg-background-700 rounded-full items-center justify-center">
              <Avatar size="lg">
                <AvatarFallbackText>
                  {group.name.substring(0, 2).toUpperCase()}
                </AvatarFallbackText>
              </Avatar>
            </Box>

            {/* Middle Section: Group Details */}
            <VStack className="flex-1 space-y-2">
              <Text className="text-xl font-bold text-text-50">
                {group.name}
              </Text>
              <HStack className="items-center space-x-2">
                <Icon as={GlobeIcon} className="w-4 h-4 text-text-300" />
                <Text className="text-sm text-text-300">
                  {group.direction || "Horizontal"}
                </Text>
              </HStack>
              <HStack className="items-center space-x-2">
                <Icon as={AvatarImage} className="w-4 h-4 text-text-300" />
                <Text className="text-sm text-text-300">
                  Member count: {group.memberCount}
                </Text>
              </HStack>
              <HStack className="items-center space-x-2">
                <Icon as={AvatarImage} className="w-4 h-4 text-text-300" />
                <Text className="text-sm text-text-300">
                  Activity: {group.activity}
                </Text>
              </HStack>
            </VStack>
          </HStack>

          {/* Hashtags Section */}
          <HStack className="flex-wrap mt-3 space-x-2">
            {group.tags?.map((tag, index) => (
              <Text key={index} className="text-xs text-primary-300">
                #{tag}
              </Text>
            ))}
          </HStack>
        </Box>
      )}
    </Pressable>
  );
};

export default GroupCard;
