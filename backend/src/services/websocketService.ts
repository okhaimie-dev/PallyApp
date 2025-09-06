import { Server as SocketIOServer } from 'socket.io';
import { Server as HTTPServer } from 'http';
import { GroupService } from './groupService';
import { DatabaseService, MessageRecord } from './databaseService';

export interface SocketUser {
  socketId: string;
  userEmail: string;
  currentGroupId?: number;
}

export interface MessageData {
  groupId: number;
  senderEmail: string;
  content: string;
  messageType?: string;
}

export interface JoinGroupData {
  groupId: number;
  userEmail: string;
}

export class WebSocketService {
  private static instance: WebSocketService;
  private io: SocketIOServer;
  private connectedUsers: Map<string, SocketUser> = new Map();
  private groupService: GroupService;
  private dbService: DatabaseService;

  private constructor(httpServer: HTTPServer) {
    this.io = new SocketIOServer(httpServer, {
      cors: {
        origin: "*", // In production, specify your Flutter app's origin
        methods: ["GET", "POST"]
      }
    });

    this.groupService = GroupService.getInstance();
    this.dbService = DatabaseService.getInstance();
    this.setupEventHandlers();
  }

  public static getInstance(httpServer?: HTTPServer): WebSocketService {
    if (!WebSocketService.instance && httpServer) {
      WebSocketService.instance = new WebSocketService(httpServer);
    }
    return WebSocketService.instance;
  }

  private setupEventHandlers(): void {
    this.io.on('connection', (socket) => {
      console.log(`🔌 User connected: ${socket.id}`);

      // Handle user authentication/identification
      socket.on('authenticate', (data: { userEmail: string }) => {
        const user: SocketUser = {
          socketId: socket.id,
          userEmail: data.userEmail,
        };
        this.connectedUsers.set(socket.id, user);
        console.log(`✅ User authenticated: ${data.userEmail} (${socket.id})`);
        
        // Join user to their personal room for notifications
        socket.join(`user:${data.userEmail}`);
      });

      // Handle joining a group chat
      socket.on('join_group', async (data: JoinGroupData) => {
        try {
          const user = this.connectedUsers.get(socket.id);
          if (!user) {
            socket.emit('error', { message: 'User not authenticated' });
            return;
          }

          // Verify user is member of the group (skip for global groups)
          const group = this.dbService.getGroupById(data.groupId);
          const isGlobalGroup = group && !group.isPrivate;
          const isMember = this.dbService.isGroupMember(data.groupId, data.userEmail);
          
          if (!isGlobalGroup && !isMember) {
            socket.emit('error', { message: 'You are not a member of this group' });
            return;
          }

          // Leave previous group room if any
          if (user.currentGroupId) {
            socket.leave(`group:${user.currentGroupId}`);
          }

          // Join new group room
          socket.join(`group:${data.groupId}`);
          user.currentGroupId = data.groupId;

          console.log(`👥 User ${data.userEmail} joined group ${data.groupId}`);
          
          // Notify other members in the group
          socket.to(`group:${data.groupId}`).emit('user_joined', {
            userEmail: data.userEmail,
            groupId: data.groupId,
            timestamp: new Date().toISOString()
          });

          socket.emit('joined_group', {
            groupId: data.groupId,
            message: 'Successfully joined group'
          });

        } catch (error) {
          console.error('❌ Error joining group:', error);
          socket.emit('error', { message: 'Failed to join group' });
        }
      });

      // Handle leaving a group chat
      socket.on('leave_group', (data: { groupId: number }) => {
        const user = this.connectedUsers.get(socket.id);
        if (!user) {
          socket.emit('error', { message: 'User not authenticated' });
          return;
        }

        socket.leave(`group:${data.groupId}`);
        if (user.currentGroupId === data.groupId) {
          delete user.currentGroupId;
        }

        console.log(`👋 User ${user.userEmail} left group ${data.groupId}`);
        
        // Notify other members in the group
        socket.to(`group:${data.groupId}`).emit('user_left', {
          userEmail: user.userEmail,
          groupId: data.groupId,
          timestamp: new Date().toISOString()
        });
      });

      // Handle sending messages
      socket.on('send_message', async (data: MessageData) => {
        try {
          const user = this.connectedUsers.get(socket.id);
          if (!user) {
            socket.emit('error', { message: 'User not authenticated' });
            return;
          }

          // Verify user is member of the group (skip for global groups)
          const group = this.dbService.getGroupById(data.groupId);
          const isGlobalGroup = group && !group.isPrivate;
          const isMember = this.dbService.isGroupMember(data.groupId, data.senderEmail);
          
          if (!isGlobalGroup && !isMember) {
            socket.emit('error', { message: 'You are not a member of this group' });
            return;
          }

          // Save message to database
          const messageResult = this.groupService.sendMessage(
            data.groupId,
            data.senderEmail,
            data.content,
            data.messageType || 'text'
          );

          if (!messageResult.success) {
            socket.emit('error', { message: messageResult.error || 'Failed to send message' });
            return;
          }

          const message = messageResult.message!;
          console.log(`💬 Message sent in group ${data.groupId} by ${data.senderEmail}`);

          // Broadcast message to all members in the group
          const messagePayload = {
            id: message.id,
            groupId: message.groupId,
            senderEmail: message.senderEmail,
            content: message.content,
            messageType: message.messageType,
            createdAt: message.createdAt,
            timestamp: new Date().toISOString()
          };

          this.io.to(`group:${data.groupId}`).emit('new_message', messagePayload);

          // Send confirmation to sender
          socket.emit('message_sent', {
            messageId: message.id,
            timestamp: new Date().toISOString()
          });

        } catch (error) {
          console.error('❌ Error sending message:', error);
          socket.emit('error', { message: 'Failed to send message' });
        }
      });

      // Handle typing indicators
      socket.on('typing_start', (data: { groupId: number; userEmail: string }) => {
        const user = this.connectedUsers.get(socket.id);
        if (!user || user.currentGroupId !== data.groupId) {
          return;
        }

        socket.to(`group:${data.groupId}`).emit('user_typing', {
          userEmail: data.userEmail,
          groupId: data.groupId,
          isTyping: true,
          timestamp: new Date().toISOString()
        });
      });

      socket.on('typing_stop', (data: { groupId: number; userEmail: string }) => {
        const user = this.connectedUsers.get(socket.id);
        if (!user || user.currentGroupId !== data.groupId) {
          return;
        }

        socket.to(`group:${data.groupId}`).emit('user_typing', {
          userEmail: data.userEmail,
          groupId: data.groupId,
          isTyping: false,
          timestamp: new Date().toISOString()
        });
      });

      // Handle group updates (new members, group info changes, etc.)
      socket.on('group_updated', (data: { groupId: number; updateType: string; data: any }) => {
        const user = this.connectedUsers.get(socket.id);
        if (!user) {
          return;
        }

        // Broadcast group update to all members
        this.io.to(`group:${data.groupId}`).emit('group_update', {
          groupId: data.groupId,
          updateType: data.updateType,
          data: data.data,
          timestamp: new Date().toISOString()
        });
      });

      // Handle disconnection
      socket.on('disconnect', () => {
        const user = this.connectedUsers.get(socket.id);
        if (user) {
          console.log(`🔌 User disconnected: ${user.userEmail} (${socket.id})`);
          
          // Notify group members if user was in a group
          if (user.currentGroupId) {
            socket.to(`group:${user.currentGroupId}`).emit('user_left', {
              userEmail: user.userEmail,
              groupId: user.currentGroupId,
              timestamp: new Date().toISOString()
            });
          }
          
          this.connectedUsers.delete(socket.id);
        }
      });
    });
  }

  // Method to broadcast group updates (called from other services)
  public broadcastGroupUpdate(groupId: number, updateType: string, data: any): void {
    this.io.to(`group:${groupId}`).emit('group_update', {
      groupId,
      updateType,
      data,
      timestamp: new Date().toISOString()
    });
  }

  // Method to notify group members about new member
  public notifyNewMember(groupId: number, newMemberEmail: string): void {
    this.io.to(`group:${groupId}`).emit('new_member', {
      groupId,
      newMemberEmail,
      timestamp: new Date().toISOString()
    });
  }

  // Method to notify group members about member leaving
  public notifyMemberLeft(groupId: number, memberEmail: string): void {
    this.io.to(`group:${groupId}`).emit('member_left', {
      groupId,
      memberEmail,
      timestamp: new Date().toISOString()
    });
  }

  // Get connected users count
  public getConnectedUsersCount(): number {
    return this.connectedUsers.size;
  }

  // Get users in a specific group
  public getUsersInGroup(groupId: number): SocketUser[] {
    return Array.from(this.connectedUsers.values()).filter(
      user => user.currentGroupId === groupId
    );
  }
}
