import 'package:flutter/material.dart';

class GoogleSigninButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const GoogleSigninButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        icon: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.black, strokeWidth: 2.5),
              )
            : const Icon(Icons.g_mobiledata, size: 32),
        label: Text(
          isLoading ? 'Connecting...' : 'Continue with Google',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        onPressed: isLoading ? null : onPressed,
      ),
    );
  }
}
