import EditScreenInfo from "@/components/EditScreenInfo";
import { Center } from "@/components/ui/center";
import { Divider } from "@/components/ui/divider";
import { Heading } from "@/components/ui/heading";
import { Text } from "@/components/ui/text";
import { useLocalSearchParams } from "expo-router";

export default function TabGroup() {
  const { id } = useLocalSearchParams<{ id: string }>();

  return (
    <Center className="flex-1 bg-black p-4">
      <Heading className="font-bold text-2xl">
        Group Details for ID: {id}
      </Heading>
      <Text className="text-xl text-white font-bold">Testing 1 2</Text>
    </Center>
  );
}
