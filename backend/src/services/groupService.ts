import { DatabaseService, GroupRecord, GroupMemberRecord, MessageRecord } from "./databaseService";
import { WebSocketService } from "./websocketService";

export interface CreateGroupRequest {
  name: string;
  description: string;
  category: string;
  icon: string;
  color: string;
  isPrivate: boolean;
  createdBy: string;
}

export interface GroupResponse {
  success: boolean;
  group?: GroupRecord;
  message: string;
}

export interface MessageResponse {
  success: boolean;
  message?: MessageRecord;
  error?: string;
}

export interface GroupsResponse {
  success: boolean;
  groups: GroupRecord[];
  message: string;
}

export interface MessagesResponse {
  success: boolean;
  messages: MessageRecord[];
  message: string;
}

export class GroupService {
  private static instance: GroupService;
  private dbService: DatabaseService;
  private wsService?: WebSocketService;

  private constructor() {
    this.dbService = DatabaseService.getInstance();
  }

  public static getInstance(): GroupService {
    if (!GroupService.instance) {
      GroupService.instance = new GroupService();
    }
    return GroupService.instance;
  }

  public setWebSocketService(wsService: WebSocketService): void {
    this.wsService = wsService;
  }

  /**
   * Create a new group
   */
  public createGroup(request: CreateGroupRequest): GroupResponse {
    try {
      // Validate required fields
      if (!request.name || !request.category || !request.createdBy) {
        return {
          success: false,
          message: "Name, category, and creator are required"
        };
      }

      // Check if group name already exists
      const existingGroups = this.dbService.getGroupsByUser(request.createdBy);
      const nameExists = existingGroups.some(group => 
        group.name.toLowerCase() === request.name.toLowerCase()
      );

      if (nameExists) {
        return {
          success: false,
          message: "A group with this name already exists"
        };
      }

      const group = this.dbService.createGroup(
        request.name,
        request.description || "",
        request.category,
        request.icon || "group",
        request.color || "#6366F1",
        request.isPrivate,
        request.createdBy
      );

      console.log(`✅ Group created: ${group.name} by ${request.createdBy}`);

      return {
        success: true,
        group,
        message: "Group created successfully"
      };

    } catch (error) {
      console.error("❌ Error creating group:", error);
      return {
        success: false,
        message: `Failed to create group: ${error instanceof Error ? error.message : "Unknown error"}`
      };
    }
  }

  /**
   * Get groups for a user
   */
  public getUserGroups(userEmail: string): GroupsResponse {
    try {
      const groups = this.dbService.getGroupsByUser(userEmail);
      
      return {
        success: true,
        groups,
        message: `Found ${groups.length} groups`
      };

    } catch (error) {
      console.error("❌ Error getting user groups:", error);
      return {
        success: false,
        groups: [],
        message: `Failed to get groups: ${error instanceof Error ? error.message : "Unknown error"}`
      };
    }
  }

  /**
   * Get public groups by category
   */
  public getPublicGroupsByCategory(category: string): GroupsResponse {
    try {
      const groups = this.dbService.getPublicGroupsByCategory(category);
      
      return {
        success: true,
        groups,
        message: `Found ${groups.length} public groups in ${category}`
      };

    } catch (error) {
      console.error("❌ Error getting public groups:", error);
      return {
        success: false,
        groups: [],
        message: `Failed to get public groups: ${error instanceof Error ? error.message : "Unknown error"}`
      };
    }
  }

  /**
   * Get group by ID
   */
  public getGroupById(groupId: number, userEmail?: string): GroupResponse {
    try {
      const group = this.dbService.getGroupById(groupId);
      
      if (!group) {
        return {
          success: false,
          message: "Group not found"
        };
      }

      // Check if user is member (for private groups) - only if userEmail is provided
      if (group.isPrivate && userEmail && !this.dbService.isGroupMember(groupId, userEmail)) {
        return {
          success: false,
          message: "Access denied. You are not a member of this group"
        };
      }

      return {
        success: true,
        group,
        message: "Group retrieved successfully"
      };

    } catch (error) {
      console.error("❌ Error getting group:", error);
      return {
        success: false,
        message: `Failed to get group: ${error instanceof Error ? error.message : "Unknown error"}`
      };
    }
  }

  /**
   * Join a group
   */
  public joinGroup(groupId: number, userEmail: string): GroupResponse {
    try {
      const group = this.dbService.getGroupById(groupId);
      
      if (!group) {
        return {
          success: false,
          message: "Group not found"
        };
      }

      // Check if user is already a member
      if (this.dbService.isGroupMember(groupId, userEmail)) {
        return {
          success: false,
          message: "You are already a member of this group"
        };
      }

      // Add user to group
      this.dbService.addGroupMember(groupId, userEmail, 'member');

      console.log(`✅ User ${userEmail} joined group ${group.name}`);

      // Notify WebSocket clients about new member
      if (this.wsService) {
        this.wsService.notifyNewMember(groupId, userEmail);
      }

      return {
        success: true,
        group,
        message: "Successfully joined the group"
      };

    } catch (error) {
      console.error("❌ Error joining group:", error);
      return {
        success: false,
        message: `Failed to join group: ${error instanceof Error ? error.message : "Unknown error"}`
      };
    }
  }

  /**
   * Leave a group
   */
  public leaveGroup(groupId: number, userEmail: string): GroupResponse {
    try {
      const group = this.dbService.getGroupById(groupId);
      
      if (!group) {
        return {
          success: false,
          message: "Group not found"
        };
      }

      // Check if user is a member
      if (!this.dbService.isGroupMember(groupId, userEmail)) {
        return {
          success: false,
          message: "You are not a member of this group"
        };
      }

      // Check if user is the creator
      if (group.createdBy === userEmail) {
        return {
          success: false,
          message: "Group creator cannot leave the group. Transfer ownership or delete the group instead."
        };
      }

      // Remove user from group
      this.dbService.removeGroupMember(groupId, userEmail);

      console.log(`✅ User ${userEmail} left group ${group.name}`);

      // Notify WebSocket clients about member leaving
      if (this.wsService) {
        this.wsService.notifyMemberLeft(groupId, userEmail);
      }

      return {
        success: true,
        group,
        message: "Successfully left the group"
      };

    } catch (error) {
      console.error("❌ Error leaving group:", error);
      return {
        success: false,
        message: `Failed to leave group: ${error instanceof Error ? error.message : "Unknown error"}`
      };
    }
  }

  /**
   * Get group members
   */
  public getGroupMembers(groupId: number, userEmail: string): { success: boolean; members: GroupMemberRecord[]; message: string } {
    try {
      const group = this.dbService.getGroupById(groupId);
      
      if (!group) {
        return {
          success: false,
          members: [],
          message: "Group not found"
        };
      }

      // Check if user is member (for private groups)
      if (group.isPrivate && !this.dbService.isGroupMember(groupId, userEmail)) {
        return {
          success: false,
          members: [],
          message: "Access denied. You are not a member of this group"
        };
      }

      const members = this.dbService.getGroupMembers(groupId);

      return {
        success: true,
        members,
        message: `Found ${members.length} members`
      };

    } catch (error) {
      console.error("❌ Error getting group members:", error);
      return {
        success: false,
        members: [],
        message: `Failed to get members: ${error instanceof Error ? error.message : "Unknown error"}`
      };
    }
  }

  /**
   * Send message to group
   */
  public sendMessage(groupId: number, senderEmail: string, content: string, messageType: string = 'text'): MessageResponse {
    try {
      const group = this.dbService.getGroupById(groupId);
      
      if (!group) {
        return {
          success: false,
          error: "Group not found"
        };
      }

      // Check if user is member (skip for public groups)
      if (group.isPrivate && !this.dbService.isGroupMember(groupId, senderEmail)) {
        return {
          success: false,
          error: "You are not a member of this group"
        };
      }

      // Validate message content
      if (!content || content.trim().length === 0) {
        return {
          success: false,
          error: "Message content cannot be empty"
        };
      }

      if (content.length > 1000) {
        return {
          success: false,
          error: "Message is too long (max 1000 characters)"
        };
      }

      const message = this.dbService.addMessage(groupId, senderEmail, content.trim(), messageType);

      console.log(`💬 Message sent to group ${group.name} by ${senderEmail}`);

      return {
        success: true,
        message
      };

    } catch (error) {
      console.error("❌ Error sending message:", error);
      return {
        success: false,
        error: `Failed to send message: ${error instanceof Error ? error.message : "Unknown error"}`
      };
    }
  }

  /**
   * Get messages for group
   */
  public getGroupMessages(groupId: number, userEmail: string, limit: number = 50, offset: number = 0): MessagesResponse {
    try {
      const group = this.dbService.getGroupById(groupId);
      
      if (!group) {
        return {
          success: false,
          messages: [],
          message: "Group not found"
        };
      }

      // Check if user is member (for private groups)
      if (group.isPrivate && !this.dbService.isGroupMember(groupId, userEmail)) {
        return {
          success: false,
          messages: [],
          message: "Access denied. You are not a member of this group"
        };
      }

      const messages = this.dbService.getGroupMessages(groupId, limit, offset);

      return {
        success: true,
        messages,
        message: `Retrieved ${messages.length} messages`
      };

    } catch (error) {
      console.error("❌ Error getting group messages:", error);
      return {
        success: false,
        messages: [],
        message: `Failed to get messages: ${error instanceof Error ? error.message : "Unknown error"}`
      };
    }
  }

  /**
   * Get recent messages for group
   */
  public getRecentGroupMessages(groupId: number, userEmail: string, limit: number = 20): MessagesResponse {
    return this.getGroupMessages(groupId, userEmail, limit, 0);
  }
}
