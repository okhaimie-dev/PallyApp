import React, { useState } from "react";
import { Box } from "@/components/ui/box";
import { Heading } from "@/components/ui/heading";
import { Text } from "@/components/ui/text";
import { VStack } from "@/components/ui/vstack";
import { useLocalSearchParams } from "expo-router";
import { ScrollView } from "react-native";
import MemberListItem from "@/components/MemberListItem";
import { MOCK_GROUPS } from "@/utils/mockData";
import {
  Modal,
  ModalBackdrop,
  ModalContent,
  ModalHeader,
  ModalCloseButton,
  ModalBody,
  ModalFooter,
} from "@/components/ui/modal";
import { Button, ButtonText } from "@/components/ui/button";
import { Icon, CloseIcon } from "@/components/ui/icon";

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
  const [showModal, setShowModal] = useState(false);
  const [selectedMember, setSelectedMember] = useState<Member | null>(null);

  const handlePressMember = (memberId: string) => {
    console.log(`Tapping on member: ${memberId}`);
    const member = MOCK_MEMBERS.find((m) => m.id === memberId);
    if (member) {
      setSelectedMember(member);
      setShowModal(true);
    }
  };

  const group = MOCK_GROUPS.find((g) => g.id === id);

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

      {/* Member Action Modal */}
      <Modal
        isOpen={showModal}
        onClose={() => {
          setShowModal(false);
          setSelectedMember(null);
        }}
        size="lg"
      >
        <ModalBackdrop />
        <ModalContent>
          <ModalHeader>
            <Heading size="lg">Member Actions</Heading>
            <ModalCloseButton>
              <Icon as={CloseIcon} />
            </ModalCloseButton>
          </ModalHeader>
          <ModalBody>
            <Text className="text-lg mb-4">
              What would you like to do with {selectedMember?.name}?
            </Text>
          </ModalBody>
          <ModalFooter>
            <Button
              variant="outline"
              action="secondary"
              className="mr-3"
              onPress={() => {
                setShowModal(false);
                setSelectedMember(null);
              }}
            >
              <ButtonText>Cancel</ButtonText>
            </Button>
            <Button
              onPress={() => {
                console.log(`Taking action on member: ${selectedMember?.name}`);
                setShowModal(false);
                setSelectedMember(null);
              }}
            >
              <ButtonText>Send Tip</ButtonText>
            </Button>
          </ModalFooter>
        </ModalContent>
      </Modal>
    </Box>
  );
}
