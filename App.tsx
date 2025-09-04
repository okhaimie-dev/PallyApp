/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 *
 * @format
 */

import React, { useEffect, useCallback } from 'react';
import { Text, View } from 'react-native';
import LinearGradient from 'react-native-linear-gradient';
import Animated, {
  Easing,
  useAnimatedStyle,
  useSharedValue,
  withDelay,
  withSequence,
  withSpring,
  withTiming
} from 'react-native-reanimated';

interface SplashScreenProps {
  onAnimationComplete?: () => void;
}

const SplashScreen: React.FC<SplashScreenProps> = ({ onAnimationComplete }) => {
  const logoScale = useSharedValue(0);
  const logoRotation = useSharedValue(0);
  const logoGlow = useSharedValue(0);
  const subtitleOpacity = useSharedValue(0);
  const subtitleTranslateY = useSharedValue(30);
  const backgroundOpacity = useSharedValue(0);
  const circleScale = useSharedValue(0);
  const circleOpacity = useSharedValue(0);
  const dotsOpacity = useSharedValue(0);
  const underlineWidth = useSharedValue(0);

  const handleAnimationComplete = useCallback(() => {
    if (onAnimationComplete) {
      onAnimationComplete();
    }
  }, [onAnimationComplete]);

  useEffect(() => {
    // Background fade in
    backgroundOpacity.value = withTiming(1, { duration: 500 });

    // Animated circles
    circleScale.value = withDelay(
      200,
      withSpring(1, {
        damping: 8,
        stiffness: 100,
      })
    );
    circleOpacity.value = withDelay(200, withTiming(0.1, { duration: 800 }));

    // Logo animation with enhanced effects
    logoScale.value = withDelay(
      400,
      withSpring(1, {
        damping: 8,
        stiffness: 120,
      })
    );

    logoRotation.value = withDelay(
      600,
      withSequence(
        withTiming(5, { duration: 600, easing: Easing.out(Easing.cubic) }),
        withTiming(0, { duration: 400 })
      )
    );

    // Glow effect animation
    logoGlow.value = withDelay(
      800,
      withSequence(
        withTiming(1, { duration: 800 }),
        withTiming(0.7, { duration: 400 })
      )
    );

    // Animated underline
    underlineWidth.value = withDelay(
      1000,
      withSpring(1, {
        damping: 8,
        stiffness: 100,
      })
    );

    // Subtitle animation
    subtitleOpacity.value = withDelay(1200, withTiming(1, { duration: 600 }));
    subtitleTranslateY.value = withDelay(
      1200,
      withSpring(0, {
        damping: 8,
        stiffness: 100,
      })
    );

    // Loading dots animation
    dotsOpacity.value = withDelay(1400, withTiming(1, { duration: 400 }));

    // Complete animation after 3 seconds
    const timer = setTimeout(() => {
      handleAnimationComplete();
    }, 3000);

    return () => clearTimeout(timer);
  }, [backgroundOpacity, circleOpacity, circleScale, dotsOpacity, logoGlow, logoRotation, logoScale, subtitleOpacity, subtitleTranslateY, underlineWidth, handleAnimationComplete]);

  const backgroundAnimatedStyle = useAnimatedStyle(() => ({
    opacity: backgroundOpacity.value,
  }));

  const circleAnimatedStyle = useAnimatedStyle(() => ({
    transform: [{ scale: circleScale.value }],
    opacity: circleOpacity.value,
  }));

  const logoAnimatedStyle = useAnimatedStyle(() => ({
    transform: [
      { scale: logoScale.value },
      { rotate: `${logoRotation.value}deg` },
    ],
  }));

  const logoGlowStyle = useAnimatedStyle(() => ({
    opacity: logoGlow.value,
  }));

  const underlineAnimatedStyle = useAnimatedStyle(() => ({
    transform: [{ scaleX: underlineWidth.value }],
  }));

  const subtitleAnimatedStyle = useAnimatedStyle(() => ({
    opacity: subtitleOpacity.value,
    transform: [{ translateY: subtitleTranslateY.value }],
  }));

  const dotsAnimatedStyle = useAnimatedStyle(() => ({
    opacity: dotsOpacity.value,
  }));

  return (
    <Animated.View 
      style={[backgroundAnimatedStyle]}
      className="flex-1 bg-dark-950 justify-center items-center relative"
    >
      {/* Gradient Background */}
      <LinearGradient
        colors={['#020617', '#0f172a', '#1e293b']}
        locations={[0, 0.5, 1]}
        className="absolute inset-0"
      />

      {/* Animated Background Circles */}
      <Animated.View 
        style={[circleAnimatedStyle]}
        className="absolute inset-0 justify-center items-center"
      >
        <View className="w-96 h-96 border border-primary-500/20 rounded-full absolute" />
        <View className="w-80 h-80 border border-primary-400/15 rounded-full absolute" />
        <View className="w-64 h-64 border border-primary-300/10 rounded-full absolute" />
      </Animated.View>

      {/* Main Content */}
      <View className="items-center z-10 px-4 flex-1 justify-center">
        {/* Animated Logo Text */}
        <Animated.View style={[logoAnimatedStyle]} className="mb-8 items-center px-8">
          <View className="relative px-12 py-8">
            {/* Background Glow Effect */}
            <Animated.View 
              style={[logoGlowStyle]}
              className="absolute inset-0 -m-8 rounded-3xl"
            >
              <LinearGradient
                colors={['transparent', '#0ea5e9', 'transparent']}
                className="flex-1 rounded-3xl opacity-20"
              />
            </Animated.View>
            
            {/* Main Title with Enhanced Glow */}
            <Text 
              className="text-white text-7xl font-bold font-space-mono tracking-wider relative z-10 text-center pt-2"
              style={{
                textShadowColor: '#0ea5e9',
                textShadowOffset: { width: 0, height: 0 },
                textShadowRadius: 20,
              }}
            >
              Pally
            </Text>
            
            {/* Animated Underline */}
            <Animated.View 
              style={[underlineAnimatedStyle]}
              className="absolute -bottom-3 left-0 right-0 h-1.5 overflow-hidden"
            >
              <LinearGradient
                colors={['transparent', '#38bdf8', '#0ea5e9', '#38bdf8', 'transparent']}
                start={{ x: 0, y: 0 }}
                end={{ x: 1, y: 0 }}
                className="flex-1 rounded-full"
              />
            </Animated.View>
            
            {/* Floating Particles */}
            <FloatingParticle delay={1200} x={-30} y={-20} />
            <FloatingParticle delay={1400} x={40} y={-10} />
            <FloatingParticle delay={1600} x={-20} y={15} />
            <FloatingParticle delay={1800} x={35} y={25} />
          </View>
        </Animated.View>

        {/* Subtitle */}
        <Animated.View style={[subtitleAnimatedStyle]}>
          <Text className="text-gray-400 text-lg text-center mb-12 px-8 leading-6">
            Connect, Chat, and Share{'\n'}
            <Text className="text-primary-400 font-semibold">Your Global Community Awaits</Text>
          </Text>
        </Animated.View>

        {/* Loading Dots */}
        <Animated.View style={[dotsAnimatedStyle]} className="flex-row space-x-2">
          <LoadingDot delay={0} />
          <LoadingDot delay={200} />
          <LoadingDot delay={400} />
        </Animated.View>
      </View>

      {/* Bottom Decoration */}
      <View className="absolute bottom-0 left-0 right-0 h-32">
        <LinearGradient
          colors={['transparent', '#020617']}
          className="flex-1"
        />
      </View>
    </Animated.View>
  );
};

const LoadingDot: React.FC<{ delay: number }> = ({ delay }) => {
  const scale = useSharedValue(1);
  const opacity = useSharedValue(0.3);

  useEffect(() => {
    const animate = () => {
      scale.value = withDelay(
        delay,
        withSequence(
          withTiming(1.5, { duration: 600 }),
          withTiming(1, { duration: 600 })
        )
      );
      opacity.value = withDelay(
        delay,
        withSequence(
          withTiming(1, { duration: 600 }),
          withTiming(0.3, { duration: 600 })
        )
      );
    };

    animate();
    const interval = setInterval(animate, 1200);
    return () => clearInterval(interval);
  }, [delay, scale, opacity]);

  const animatedStyle = useAnimatedStyle(() => ({
    transform: [{ scale: scale.value }],
    opacity: opacity.value,
  }));

  return (
    <Animated.View 
      style={[animatedStyle]}
      className="w-3 h-3 bg-primary-500 rounded-full"
    />
  );
};

const FloatingParticle: React.FC<{ delay: number; x: number; y: number }> = ({ delay, x, y }) => {
  const translateY = useSharedValue(0);
  const opacity = useSharedValue(0);
  const scale = useSharedValue(0);

  useEffect(() => {
    opacity.value = withDelay(delay, withTiming(0.6, { duration: 800 }));
    scale.value = withDelay(delay, withSpring(1, { damping: 8, stiffness: 100 }));
    
    const animate = () => {
      translateY.value = withSequence(
        withTiming(-10, { duration: 2000, easing: Easing.inOut(Easing.sin) }),
        withTiming(0, { duration: 2000, easing: Easing.inOut(Easing.sin) })
      );
    };

    const timer = setTimeout(animate, delay);
    const interval = setInterval(animate, 4000);
    
    return () => {
      clearTimeout(timer);
      clearInterval(interval);
    };
  }, [delay, opacity, scale, translateY]);

  const animatedStyle = useAnimatedStyle(() => ({
    transform: [
      { translateX: x },
      { translateY: y + translateY.value },
      { scale: scale.value }
    ],
    opacity: opacity.value,
  }));

  return (
    <Animated.View 
      style={[animatedStyle]}
      className="w-2 h-2 bg-primary-400 rounded-full"
    />
  );
};

export default SplashScreen;
