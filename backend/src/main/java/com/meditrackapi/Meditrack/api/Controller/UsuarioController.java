package com.meditrackapi.Meditrack.api.Controller;

import com.meditrackapi.Meditrack.domain.DTOs.UsuarioTOs.*;
import com.meditrackapi.Meditrack.domain.Entities.Usuario;
import com.meditrackapi.Meditrack.domain.Interfaces.IUsuarioService;
import jakarta.validation.Valid;
import org.apache.coyote.Response;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/usuario")
public class UsuarioController {

    private final IUsuarioService _usuarioService;

    public UsuarioController(IUsuarioService usuarioService){
        _usuarioService = usuarioService;
    }

    @PostMapping("/cadastro")
    public ResponseEntity<UsuarioResponseDTO> cadastrarUsuario(@RequestBody @Valid PostUsuarioDTO novoUsuario){
        UsuarioResponseDTO response = _usuarioService.cadastrarUsuario(novoUsuario);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/confirmar-email/{userId}/{authCode}")
    public ResponseEntity<String> confirmarEmail(@PathVariable String userId, @PathVariable String authCode){
        boolean validado = _usuarioService.confirmarEmail(userId, authCode);
        if (validado) {
            return ResponseEntity.ok("Email confirmado com sucesso.");
        } else {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Código de autenticação inválido.");
        }
    }

    @PutMapping("/editar")
    public ResponseEntity<UsuarioResponseDTO> editarUsuario(@RequestBody @Valid EditUsuarioDTO usuarioInfos){
        UsuarioResponseDTO response = _usuarioService.editarUsuario(usuarioInfos);
        return ResponseEntity.ok(response);
    }

    @PutMapping("/trocar-senha")
    public ResponseEntity<String> trocarSenha(@RequestBody String newPassword){
        _usuarioService.ChangePassword(newPassword);
        return ResponseEntity.ok("Senha alterada.");
    }

    @GetMapping("")
    public ResponseEntity<UsuarioResponseDTO> getUsuarioByAuthToken(){
        UsuarioResponseDTO response = _usuarioService.getUsuarioByAuthToken();
        return ResponseEntity.ok(response);
    }

    @PostMapping("/login")
    public ResponseEntity<LoginResponseDTO> login(@RequestBody @Valid UserLoginDTO userLogin){
        LoginResponseDTO response = _usuarioService.login(userLogin);
        return  ResponseEntity.ok(response);
    }

    @GetMapping("/listar")
    public ResponseEntity<List<Usuario>> listarTodosUsuarios() {
        List<Usuario> usuarios = _usuarioService.listarTodosUsuarios();
        return ResponseEntity.ok(usuarios);
    }
}
