import { Stack, useRouter } from "expo-router";
import { Pressable } from "react-native";
import { Text } from "@/components/ui/text";
import FontAwesome from "@expo/vector-icons/FontAwesome";

export function ModalIcon(props: {
  name: React.ComponentProps<typeof FontAwesome>["name"];
}) {
  return <FontAwesome size={18} style={{ marginBottom: -3 }} {...props} />;
}

export default function GroupModalLayout() {
  const router = useRouter();
  return (
    <Stack
      screenOptions={{
        presentation: "modal",
        headerShown: true,
        headerLeft: () => (
          <Pressable onPress={() => router.back()}>
            <Text className="text-blue-500 ml-4">
              <ModalIcon name="close" />
            </Text>
          </Pressable>
        ),
      }}
    >
      <Stack.Screen
        name="[id]"
        options={{
          title: "Group Details",
        }}
      />
    </Stack>
  );
}
