import 'package:app/widgets/bottom_nav_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:math' as math;
import 'main.dart';
import 'widgets/loading_animation.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  late AnimationController _animationController;
  late AnimationController _cloudController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final List<CloudParticle> _particles = List.generate(
    15,
    (index) => CloudParticle(
      position: Offset(
        math.Random().nextDouble() * 400,
        math.Random().nextDouble() * 800,
      ),
      size: math.Random().nextDouble() * 100 + 50,
      opacity: math.Random().nextDouble() * 0.3,
      speed: math.Random().nextDouble() * 2 + 1,
    ),
  );

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );

    _cloudController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 10),
    )..repeat();

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.0, 0.5, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.2, 0.7, curve: Curves.easeOut),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _cloudController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      if (mounted) {
        navigateWithTransition(context, BottomNavWrapper());
      }
    } catch (error) {
      print('Sign-in error: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign-in failed. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? LoadingAnimation(
              logoPath: 'assets/farmdirect.png',
              backgroundColor: Colors.white,
              size: 150.0,
            )
          : Stack(
              children: [
                // Animated Background
                ...List.generate(_particles.length, (index) {
                  return AnimatedBuilder(
                    animation: _cloudController,
                    builder: (context, child) {
                      final progress = _cloudController.value;
                      final particle = _particles[index];
                      final offset = particle.getPosition(progress);
                      
                      return Positioned(
                        left: offset.dx,
                        top: offset.dy,
                        child: Transform.scale(
                          scale: 1.0 + (math.sin(progress * math.pi * 2) * 0.1),
                          child: Opacity(
                            opacity: particle.opacity * (0.8 + math.sin(progress * math.pi * 2) * 0.2),
                            child: Container(
                              width: particle.size,
                              height: particle.size,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.green.shade100.withOpacity(0.1),
                                    Colors.green.shade50.withOpacity(0.05),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),

                // Main Content
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.green.shade50.withOpacity(0.9),
                        Colors.white.withOpacity(0.9),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Spacer(flex: 2),
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: Column(
                                children: [
                                  TweenAnimationBuilder(
                                    tween: Tween<double>(begin: 0, end: 1),
                                    duration: Duration(milliseconds: 1000),
                                    builder: (context, double value, child) {
                                      return Transform.scale(
                                        scale: value,
                                        child: child,
                                      );
                                    },
                                    child: Image.asset(
                                      'assets/farmdirect.png',
                                      height: 120,
                                      width: 120,
                                    ),
                                  ),
                                  SizedBox(height: 24),
                                  ShaderMask(
                                    shaderCallback: (bounds) => LinearGradient(
                                      colors: [
                                        Colors.green.shade800,
                                        Colors.green.shade500,
                                      ],
                                    ).createShader(bounds),
                                    child: Text(
                                      'FarmBid',
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: Text(
                              'Connect • Bid • Grow',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade700,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          Spacer(flex: 2),
                          SlideTransition(
                            position: _slideAnimation,
                            child: Container(
                              width: double.infinity,
                              child: _buildAnimatedButton(),
                            ),
                          ),
                          SizedBox(height: 16),
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: Text(
                              'By continuing, you agree to our Terms & Privacy Policy',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Spacer(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAnimatedButton() {
    return MouseRegion(
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 1, end: 1.0),
        duration: Duration(milliseconds: 200),
        builder: (context, double value, child) {
          return Transform.scale(
            scale: value,
            child: ElevatedButton.icon(
              icon: Image.asset(
                'assets/google_logo.png',
                height: 24,
                width: 24,
              ),
              label: Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Sign in with Google',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
              onPressed: _signInWithGoogle,
            ),
          );
        },
      ),
    );
  }
}

class CloudParticle {
  final Offset position;
  final double size;
  final double opacity;
  final double speed;

  CloudParticle({
    required this.position,
    required this.size,
    required this.opacity,
    required this.speed,
  });

  Offset getPosition(double progress) {
    final time = progress * speed;
    return Offset(
      position.dx + math.sin(time * math.pi * 2) * 30,
      position.dy - (progress * size * 2) % 800,
    );
  }
}

