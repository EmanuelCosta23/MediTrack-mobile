import 'package:flutter/material.dart';

class PhoneIllustration extends StatelessWidget {
  final double size;

  const PhoneIllustration({
    super.key,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Elementos de fundo (nuvens, ondas, etc.)
          Positioned(
            top: 10,
            right: 0,
            child: _buildCloud(30, Colors.white.withOpacity(0.2)),
          ),
          Positioned(
            top: 0,
            left: 20,
            child: _buildCloud(40, Colors.white.withOpacity(0.3)),
          ),
          
          // Ilustração do telefone
          Container(
            width: size * 0.7,
            height: size * 0.9,
            decoration: BoxDecoration(
              color: Color(0xFF4CD2DC),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Tela do telefone
                Container(
                  width: size * 0.6,
                  height: size * 0.6,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.medical_services_outlined,
                      size: size * 0.25,
                      color: Color(0xFF4CD2DC),
                    ),
                  ),
                ),
                
                // Botão home
                SizedBox(height: 10),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          
          // Elementos sobrepostos (pílulas, símbolos médicos)
          Positioned(
            left: 10,
            bottom: 30,
            child: _buildMedicineSymbol(40, Colors.white.withOpacity(0.7)),
          ),
          Positioned(
            right: 15,
            bottom: 50,
            child: Container(
              width: 30,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
          
          // Símbolos de adição (+) para contexto médico
          Positioned(
            right: 30,
            top: 40,
            child: Icon(
              Icons.add,
              color: Colors.white.withOpacity(0.7),
              size: 24,
            ),
          ),
          Positioned(
            left: 40,
            top: 60,
            child: Icon(
              Icons.add,
              color: Colors.white.withOpacity(0.7),
              size: 16,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCloud(double size, Color color) {
    return Container(
      width: size,
      height: size * 0.6,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size / 2),
      ),
    );
  }
  
  Widget _buildMedicineSymbol(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          Icons.local_pharmacy,
          color: Color(0xFF4CD2DC),
          size: size * 0.6,
        ),
      ),
    );
  }
} 