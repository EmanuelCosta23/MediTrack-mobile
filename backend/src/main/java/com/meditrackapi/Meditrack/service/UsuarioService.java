package com.meditrackapi.Meditrack.service;

import com.meditrackapi.Meditrack.dao.Repositories.UsuarioRepository;
import com.meditrackapi.Meditrack.domain.DTOs.UsuarioTOs.*;
import com.meditrackapi.Meditrack.domain.Entities.Usuario;
import com.meditrackapi.Meditrack.domain.Interfaces.IAuthenticationService;
import com.meditrackapi.Meditrack.domain.Interfaces.IEmailService;
import com.meditrackapi.Meditrack.domain.Interfaces.IUsuarioService;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Objects;

@Service
public class UsuarioService implements IUsuarioService {

    private final UsuarioRepository _usuarioRepo;
    private final IAuthenticationService _authService;
    private final AuthenticationManager _authenticationManager;
    private final PasswordEncoder _passwordEncoder;
    private final IEmailService _emailService;

    public UsuarioService(
            UsuarioRepository usuarioRepo,
            AuthenticationManager authenticationManager,
            IAuthenticationService authService,
            PasswordEncoder passwordEncoder,
            IEmailService emailService)
    {
        _usuarioRepo = usuarioRepo;
        _authenticationManager = authenticationManager;
        _authService = authService;
        _passwordEncoder = passwordEncoder;
        _emailService = emailService;
    }

    @Override
    public UsuarioResponseDTO cadastrarUsuario(PostUsuarioDTO novoUsuario)
    {
        Usuario checkEmailAndCpf = _usuarioRepo.findByEmailOrCpf(novoUsuario.email(), novoUsuario.cpf());
        if(checkEmailAndCpf != null){
            throw new IllegalArgumentException("Usuario com este email ou cpf ja existe");
        }

        String encryptedPassword = _passwordEncoder.encode(novoUsuario.senha());
        Usuario usuario = new Usuario(novoUsuario, encryptedPassword);

        String codigoVerificacao = java.util.UUID.randomUUID().toString();
        usuario.setCodigoVerificacao(codigoVerificacao);
        _usuarioRepo.save(usuario);

        String URL = "http://localhost:5173/confirmar-email";
        String link = URL + "/" + usuario.getId() + "/" + codigoVerificacao;
        String body = "<p>Bem-vindo ao Meditrack! Você pode verificar seu email clicando "
                + "<a href=\"" + link + "\">aqui</a>.</p>";

        _emailService.SendMail(usuario.getEmail(), "Confirmação de email", body);

        return new UsuarioResponseDTO(
                usuario.getId(),
                usuario.getNomeCompleto(),
                usuario.getEmail(),
                usuario.getCpf(),
                usuario.getFotoPerfil(),
                usuario.getTipo().toString()
        );
    }

    @Override
    public boolean confirmarEmail(String userId, String authCode){
        Usuario usuario = _usuarioRepo.findById(userId)
                .orElseThrow(()-> new IllegalArgumentException("Usuario nao encontrado."));
        if(Objects.equals(usuario.getCodigoVerificacao(), authCode)){
            usuario.setIsVerificado(true);
            _usuarioRepo.save(usuario);
            return true;
        }
        return false;
    }

    @Override
    public void ChangePassword(String newPassword){
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String loggedInUserEmail = authentication.getName();
        Usuario usuarioLogado = (Usuario) _usuarioRepo.findByEmail(loggedInUserEmail);

        String encryptedNewPassword = _passwordEncoder.encode(newPassword);
        usuarioLogado.setSenha(encryptedNewPassword);
        _usuarioRepo.save(usuarioLogado);
    }

    @Override
    public UsuarioResponseDTO getUsuarioByAuthToken(){
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String loggedInUserEmail = authentication.getName();
        Usuario usuario = (Usuario) _usuarioRepo.findByEmail(loggedInUserEmail);

        return new UsuarioResponseDTO(
                usuario.getId(),
                usuario.getNomeCompleto(),
                usuario.getEmail(),
                usuario.getCpf(),
                usuario.getFotoPerfil(),
                usuario.getTipo().toString()
        );
    }

    @Override
    public UsuarioResponseDTO editarUsuario(EditUsuarioDTO usuarioInfos){
        Usuario usuario = _usuarioRepo.findById(usuarioInfos.usuarioId())
                .orElseThrow(()-> new IllegalArgumentException("Não foi possível encontrar o usuário."));

        usuario.setEmail(usuarioInfos.novoEmail());
        usuario.setNomeCompleto(usuarioInfos.novoNome());
        usuario.setDataNascimento(usuarioInfos.novaDataNascimento());

        _usuarioRepo.save(usuario);

        return new UsuarioResponseDTO(
                usuario.getId(),
                usuario.getNomeCompleto(),
                usuario.getEmail(),
                usuario.getCpf(),
                usuario.getFotoPerfil(),
                usuario.getTipo().toString()
        );
    }

    @Override
    public LoginResponseDTO login(UserLoginDTO userLogin)
    {
        UsernamePasswordAuthenticationToken authenticationToken = new UsernamePasswordAuthenticationToken(
                userLogin.email(),
                userLogin.senha()
        );
        Authentication auth = _authenticationManager.authenticate(authenticationToken);
        Usuario usuario = (Usuario) auth.getPrincipal();

        if(!usuario.getIsVerificado()){
            throw new IllegalArgumentException("Email ainda não validado.");
        }

        String jwtToken = _authService.createToken(usuario);

        UsuarioResponseDTO usuarioResponse = new UsuarioResponseDTO(
                usuario.getId(),
                usuario.getNomeCompleto(),
                usuario.getEmail(),
                usuario.getCpf(),
                usuario.getFotoPerfil(),
                usuario.getTipo().toString()
            );

        return new LoginResponseDTO(
                jwtToken,
                usuarioResponse
            );
    }

    @Override
    public List<Usuario> listarTodosUsuarios() {
        return _usuarioRepo.findAll();
    }
}
