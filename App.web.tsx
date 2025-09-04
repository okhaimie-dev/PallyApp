/**
 * Web-optimized version of the Pally App
 */

import React, { useEffect, useCallback } from 'react';
import { Text, View } from 'react-native';

interface SplashScreenProps {
  onAnimationComplete?: () => void;
}

const SplashScreen: React.FC<SplashScreenProps> = ({ onAnimationComplete }) => {
  const handleAnimationComplete = useCallback(() => {
    if (onAnimationComplete) {
      onAnimationComplete();
    }
  }, [onAnimationComplete]);

  useEffect(() => {
    // Complete animation after 3 seconds
    const timer = setTimeout(() => {
      handleAnimationComplete();
    }, 3000);

    return () => clearTimeout(timer);
  }, [handleAnimationComplete]);

  return (
    <View 
      style={{
        flex: 1,
        backgroundColor: '#020617',
        justifyContent: 'center',
        alignItems: 'center',
        position: 'relative',
      }}
    >
      {/* Background Circles */}
      <View style={{
        position: 'absolute',
        inset: 0,
        justifyContent: 'center',
        alignItems: 'center',
      }}>
        <View style={{
          width: 384,
          height: 384,
          borderWidth: 1,
          borderColor: 'rgba(14, 165, 233, 0.2)',
          borderRadius: 9999,
          position: 'absolute',
        }} />
        <View style={{
          width: 320,
          height: 320,
          borderWidth: 1,
          borderColor: 'rgba(14, 165, 233, 0.15)',
          borderRadius: 9999,
          position: 'absolute',
        }} />
        <View style={{
          width: 256,
          height: 256,
          borderWidth: 1,
          borderColor: 'rgba(14, 165, 233, 0.1)',
          borderRadius: 9999,
          position: 'absolute',
        }} />
      </View>

      {/* Main Content */}
      <View style={{
        alignItems: 'center',
        zIndex: 10,
        paddingHorizontal: 16,
        flex: 1,
        justifyContent: 'center',
      }}>
        {/* Logo Text */}
        <View style={{
          marginBottom: 32,
          alignItems: 'center',
          paddingHorizontal: 32,
        }}>
          <View style={{
            position: 'relative',
            paddingHorizontal: 48,
            paddingVertical: 32,
          }}>
            {/* Main Title */}
            <Text style={{
              color: 'white',
              fontSize: 72,
              fontWeight: 'bold',
              fontFamily: 'monospace',
              letterSpacing: 2,
              textAlign: 'center',
              paddingTop: 8,
              textShadow: '0 0 20px #0ea5e9',
            }}>
              Pally
            </Text>
            
            {/* Underline */}
            <View style={{
              position: 'absolute',
              bottom: -12,
              left: 0,
              right: 0,
              height: 6,
              backgroundColor: '#0ea5e9',
              borderRadius: 9999,
            }} />
          </View>
        </View>

        {/* Subtitle */}
        <View style={{
          marginBottom: 48,
          paddingHorizontal: 32,
        }}>
          <Text style={{
            color: '#9ca3af',
            fontSize: 18,
            textAlign: 'center',
            lineHeight: 24,
          }}>
            Connect, Chat, and Share{'\n'}
            <Text style={{
              color: '#0ea5e9',
              fontWeight: '600',
            }}>
              Your Global Community Awaits
            </Text>
          </Text>
        </View>

        {/* Loading Dots */}
        <View style={{
          flexDirection: 'row',
          gap: 8,
        }}>
          <LoadingDot />
          <LoadingDot />
          <LoadingDot />
        </View>
      </View>

      {/* Bottom Decoration */}
      <View style={{
        position: 'absolute',
        bottom: 0,
        left: 0,
        right: 0,
        height: 128,
        background: 'linear-gradient(transparent, #020617)',
      }} />
    </View>
  );
};

const LoadingDot: React.FC = () => {
  return (
    <View style={{
      width: 12,
      height: 12,
      backgroundColor: '#0ea5e9',
      borderRadius: 9999,
    }} />
  );
};

export default SplashScreen;
