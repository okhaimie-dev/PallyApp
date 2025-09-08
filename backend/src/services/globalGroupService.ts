import { DatabaseService } from './databaseService';
import { GroupService } from './groupService';

export interface CategoryConfig {
  name: string;
  icon: string;
  color: string;
  description: string;
  globalGroups: GlobalGroupConfig[];
}

export interface GlobalGroupConfig {
  name: string;
  description: string;
  icon: string;
  color: string;
  isPopular?: boolean;
}

export class GlobalGroupService {
  private static instance: GlobalGroupService;
  private dbService: DatabaseService;
  private groupService: GroupService;

  private constructor() {
    this.dbService = DatabaseService.getInstance();
    this.groupService = GroupService.getInstance();
  }

  public static getInstance(): GlobalGroupService {
    if (!GlobalGroupService.instance) {
      GlobalGroupService.instance = new GlobalGroupService();
    }
    return GlobalGroupService.instance;
  }

  /**
   * Get all category configurations with their global groups
   */
  private getCategoryConfigs(): CategoryConfig[] {
    return [
      {
        name: 'Technology',
        icon: 'computer',
        color: '#10B981',
        description: 'Discuss the latest in tech, programming, and innovation',
        globalGroups: [
          {
            name: 'Tech News & Updates',
            description: 'Stay updated with the latest technology news and trends',
            icon: 'newspaper',
            color: '#10B981',
            isPopular: true
          },
          {
            name: 'Programming & Development',
            description: 'Share code, ask questions, and discuss programming topics',
            icon: 'code',
            color: '#10B981'
          },
          {
            name: 'AI & Machine Learning',
            description: 'Explore artificial intelligence and machine learning discussions',
            icon: 'psychology',
            color: '#10B981'
          },
          {
            name: 'Web Development',
            description: 'Frontend, backend, and full-stack development discussions',
            icon: 'web',
            color: '#10B981'
          }
        ]
      },
      {
        name: 'Gaming',
        icon: 'sports_esports',
        color: '#F59E0B',
        description: 'Connect with fellow gamers and discuss your favorite games',
        globalGroups: [
          {
            name: 'Gaming General',
            description: 'General gaming discussions and news',
            icon: 'sports_esports',
            color: '#F59E0B',
            isPopular: true
          },
          {
            name: 'Mobile Gaming',
            description: 'Discuss mobile games, strategies, and tips',
            icon: 'phone_android',
            color: '#F59E0B'
          },
          {
            name: 'PC Gaming',
            description: 'PC gaming discussions, hardware, and game recommendations',
            icon: 'computer',
            color: '#F59E0B'
          },
          {
            name: 'Console Gaming',
            description: 'PlayStation, Xbox, Nintendo discussions',
            icon: 'videogame_asset',
            color: '#F59E0B'
          }
        ]
      },
      {
        name: 'Music',
        icon: 'music_note',
        color: '#EF4444',
        description: 'Share your favorite music and discover new artists',
        globalGroups: [
          {
            name: 'Music Discovery',
            description: 'Share and discover new music from all genres',
            icon: 'music_note',
            color: '#EF4444',
            isPopular: true
          },
          {
            name: 'Hip Hop & Rap',
            description: 'Discuss hip hop, rap, and urban music',
            icon: 'mic',
            color: '#EF4444'
          },
          {
            name: 'Electronic & EDM',
            description: 'Electronic music, EDM, and dance music discussions',
            icon: 'graphic_eq',
            color: '#EF4444'
          },
          {
            name: 'Rock & Alternative',
            description: 'Rock, alternative, and indie music discussions',
            icon: 'guitar',
            color: '#EF4444'
          }
        ]
      },
      {
        name: 'Art',
        icon: 'palette',
        color: '#EC4899',
        description: 'Showcase your creativity and appreciate others\' artwork',
        globalGroups: [
          {
            name: 'Digital Art',
            description: 'Share digital artwork, illustrations, and designs',
            icon: 'palette',
            color: '#EC4899',
            isPopular: true
          },
          {
            name: 'Traditional Art',
            description: 'Paintings, drawings, and traditional art forms',
            icon: 'brush',
            color: '#EC4899'
          },
          {
            name: 'Photography',
            description: 'Share photos, photography tips, and techniques',
            icon: 'camera_alt',
            color: '#EC4899'
          },
          {
            name: 'Art Critique & Feedback',
            description: 'Get feedback on your artwork and help others improve',
            icon: 'rate_review',
            color: '#EC4899'
          }
        ]
      },
      {
        name: 'Sports',
        icon: 'sports_soccer',
        color: '#8B5CF6',
        description: 'Discuss your favorite sports and teams',
        globalGroups: [
          {
            name: 'Football/Soccer',
            description: 'Discuss football, soccer, and the beautiful game',
            icon: 'sports_soccer',
            color: '#8B5CF6',
            isPopular: true
          },
          {
            name: 'Basketball',
            description: 'NBA, college basketball, and basketball discussions',
            icon: 'sports_basketball',
            color: '#8B5CF6'
          },
          {
            name: 'Tennis',
            description: 'Tennis matches, players, and tournament discussions',
            icon: 'sports_tennis',
            color: '#8B5CF6'
          },
          {
            name: 'Fitness & Training',
            description: 'Workout tips, fitness goals, and training discussions',
            icon: 'fitness_center',
            color: '#8B5CF6'
          }
        ]
      },
      {
        name: 'General',
        icon: 'group',
        color: '#6366F1',
        description: 'General discussions and community chat',
        globalGroups: [
          {
            name: 'General Chat',
            description: 'Casual conversations and general discussions',
            icon: 'chat',
            color: '#6366F1',
            isPopular: true
          },
          {
            name: 'Introductions',
            description: 'Introduce yourself and meet new people',
            icon: 'person_add',
            color: '#6366F1'
          },
          {
            name: 'Random',
            description: 'Random thoughts, memes, and fun discussions',
            icon: 'casino',
            color: '#6366F1'
          }
        ]
      },
      {
        name: 'Business',
        icon: 'business',
        color: '#06B6D4',
        description: 'Network with professionals and discuss business topics',
        globalGroups: [
          {
            name: 'Entrepreneurship',
            description: 'Startup discussions, business ideas, and entrepreneurship',
            icon: 'business',
            color: '#06B6D4',
            isPopular: true
          },
          {
            name: 'Career & Jobs',
            description: 'Career advice, job opportunities, and professional development',
            icon: 'work',
            color: '#06B6D4'
          },
          {
            name: 'Finance & Investing',
            description: 'Personal finance, investing, and money management',
            icon: 'trending_up',
            color: '#06B6D4'
          }
        ]
      },
      {
        name: 'Education',
        icon: 'school',
        color: '#84CC16',
        description: 'Learn and share knowledge across various subjects',
        globalGroups: [
          {
            name: 'Study Groups',
            description: 'Form study groups and help each other learn',
            icon: 'school',
            color: '#84CC16',
            isPopular: true
          },
          {
            name: 'Language Learning',
            description: 'Practice languages and help others learn',
            icon: 'translate',
            color: '#84CC16'
          },
          {
            name: 'Academic Discussions',
            description: 'Discuss academic topics and share knowledge',
            icon: 'menu_book',
            color: '#84CC16'
          }
        ]
      }
    ];
  }

  /**
   * Create all global groups for all categories
   */
  public async createAllGlobalGroups(): Promise<{ success: boolean; message: string; created: number; skipped: number }> {
    try {
      console.log('🚀 Starting global groups creation...');
      
      const categoryConfigs = this.getCategoryConfigs();
      let created = 0;
      let skipped = 0;
      const systemEmail = 'system@pally.app'; // System user for global groups

      for (const category of categoryConfigs) {
        console.log(`📁 Processing category: ${category.name}`);
        
        for (const groupConfig of category.globalGroups) {
          try {
            // Check if group already exists
            const existingGroups = this.dbService.getGroupsByUser(systemEmail);
            const groupExists = existingGroups.some(group => 
              group.name.toLowerCase() === groupConfig.name.toLowerCase() &&
              group.category === category.name
            );

            if (groupExists) {
              console.log(`⏭️  Skipping existing group: ${groupConfig.name}`);
              skipped++;
              continue;
            }

            // Create the group
            const result = this.groupService.createGroup({
              name: groupConfig.name,
              description: groupConfig.description,
              category: category.name,
              icon: groupConfig.icon,
              color: groupConfig.color,
              isPrivate: false, // All global groups are public
              createdBy: systemEmail
            });

            if (result.success) {
              console.log(`✅ Created global group: ${groupConfig.name} in ${category.name}`);
              created++;
            } else {
              console.log(`❌ Failed to create group: ${groupConfig.name} - ${result.message}`);
              skipped++;
            }
          } catch (error) {
            console.error(`❌ Error creating group ${groupConfig.name}:`, error);
            skipped++;
          }
        }
      }

      const message = `Global groups creation completed. Created: ${created}, Skipped: ${skipped}`;
      console.log(`🎉 ${message}`);
      
      return {
        success: true,
        message,
        created,
        skipped
      };

    } catch (error) {
      console.error('❌ Error in createAllGlobalGroups:', error);
      return {
        success: false,
        message: `Failed to create global groups: ${error instanceof Error ? error.message : 'Unknown error'}`,
        created: 0,
        skipped: 0
      };
    }
  }

  /**
   * Create global groups for a specific category
   */
  public async createGlobalGroupsForCategory(categoryName: string): Promise<{ success: boolean; message: string; created: number; skipped: number }> {
    try {
      const categoryConfigs = this.getCategoryConfigs();
      const category = categoryConfigs.find(cat => cat.name.toLowerCase() === categoryName.toLowerCase());
      
      if (!category) {
        return {
          success: false,
          message: `Category '${categoryName}' not found`,
          created: 0,
          skipped: 0
        };
      }

      console.log(`📁 Creating global groups for category: ${category.name}`);
      
      let created = 0;
      let skipped = 0;
      const systemEmail = 'system@pally.app';

      for (const groupConfig of category.globalGroups) {
        try {
          // Check if group already exists
          const existingGroups = this.dbService.getGroupsByUser(systemEmail);
          const groupExists = existingGroups.some(group => 
            group.name.toLowerCase() === groupConfig.name.toLowerCase() &&
            group.category === category.name
          );

          if (groupExists) {
            console.log(`⏭️  Skipping existing group: ${groupConfig.name}`);
            skipped++;
            continue;
          }

          // Create the group
          const result = this.groupService.createGroup({
            name: groupConfig.name,
            description: groupConfig.description,
            category: category.name,
            icon: groupConfig.icon,
            color: groupConfig.color,
            isPrivate: false,
            createdBy: systemEmail
          });

          if (result.success) {
            console.log(`✅ Created global group: ${groupConfig.name} in ${category.name}`);
            created++;
          } else {
            console.log(`❌ Failed to create group: ${groupConfig.name} - ${result.message}`);
            skipped++;
          }
        } catch (error) {
          console.error(`❌ Error creating group ${groupConfig.name}:`, error);
          skipped++;
        }
      }

      const message = `Global groups creation for ${category.name} completed. Created: ${created}, Skipped: ${skipped}`;
      console.log(`🎉 ${message}`);
      
      return {
        success: true,
        message,
        created,
        skipped
      };

    } catch (error) {
      console.error('❌ Error in createGlobalGroupsForCategory:', error);
      return {
        success: false,
        message: `Failed to create global groups for ${categoryName}: ${error instanceof Error ? error.message : 'Unknown error'}`,
        created: 0,
        skipped: 0
      };
    }
  }

  /**
   * Get all available categories
   */
  public getAvailableCategories(): CategoryConfig[] {
    return this.getCategoryConfigs();
  }

  /**
   * Get popular groups across all categories
   */
  public getPopularGroups(): GlobalGroupConfig[] {
    const categoryConfigs = this.getCategoryConfigs();
    const popularGroups: GlobalGroupConfig[] = [];

    for (const category of categoryConfigs) {
      for (const group of category.globalGroups) {
        if (group.isPopular) {
          popularGroups.push({
            ...group,
            name: `${group.name} (${category.name})`
          });
        }
      }
    }

    return popularGroups;
  }
}
