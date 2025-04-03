package com.meditrackapi.Meditrack.service;

import com.meditrackapi.Meditrack.dao.Repositories.PostoRepository;
import com.meditrackapi.Meditrack.dao.Repositories.UsuarioRepository;
import com.meditrackapi.Meditrack.domain.DTOs.UsuarioTOs.FuncionarioSignupRequest;
import com.meditrackapi.Meditrack.domain.DTOs.UsuarioTOs.PostUsuarioDTO;
import com.meditrackapi.Meditrack.domain.DTOs.UsuarioTOs.UsuarioResponseDTO;
import com.meditrackapi.Meditrack.domain.Entities.Posto;
import com.meditrackapi.Meditrack.domain.Entities.Usuario;
import com.meditrackapi.Meditrack.domain.Enums.Role;
import com.meditrackapi.Meditrack.domain.Interfaces.IAdminService;
import com.meditrackapi.Meditrack.domain.Interfaces.IEmailService;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.security.SecureRandom;
import java.util.stream.Collectors;
import java.util.stream.IntStream;

@Service
public class AdminService implements IAdminService {
    private static final SecureRandom RANDOM = new SecureRandom();
    private static final String CHARACTERS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*()-_+=<>?";
    private final PasswordEncoder _passwordEncoder;
    private final UsuarioRepository _usuarioRepo;
    private final PostoRepository _postoRepo;
    private final IEmailService _emailService;
    public AdminService(UsuarioRepository usuarioRepository,
                        PasswordEncoder passwordEncoder,
                        PostoRepository postoRepository,
                        IEmailService emailService
    ) {
        _usuarioRepo = usuarioRepository;
        _passwordEncoder = passwordEncoder;
        _postoRepo = postoRepository;
        _emailService = emailService;
    }

    private static String generateRandom10CharPassword() {
        return IntStream.range(0, 10)
                .map(i -> RANDOM.nextInt(CHARACTERS.length()))
                .mapToObj(CHARACTERS::charAt)
                .map(Object::toString)
                .collect(Collectors.joining());
    }

    @Override
    public UsuarioResponseDTO cadastrarFuncionario(FuncionarioSignupRequest novoUsuario){
        Usuario checkEmailAndCpf = _usuarioRepo.findByEmailOrCpf(novoUsuario.email(), novoUsuario.cpf());
        if(checkEmailAndCpf != null){
            throw new IllegalArgumentException("Usuario com este email ou cpf ja existe");
        }
        Posto posto = _postoRepo.findById(novoUsuario.postoId())
                .orElseThrow(() -> new IllegalArgumentException("Posto não encontrado, verifique os dados."));

        String randomPassword = generateRandom10CharPassword();

        String body = "Olá, " + novoUsuario.nomeCompleto() + " voce foi cadastrado por um administrador," +
                " sua senha de acesso é: " + randomPassword;

        _emailService.SendMail(novoUsuario.email(), "Bem vindo ao Meditrack.", body);

        String encryptedPassword = _passwordEncoder.encode(randomPassword);

        PostUsuarioDTO usuarioDTO = new PostUsuarioDTO(
                novoUsuario.nomeCompleto(),
                novoUsuario.cpf(),
                novoUsuario.email(),
                encryptedPassword,
                novoUsuario.dataNascimento()
        );
        Usuario usuario = new Usuario(usuarioDTO, encryptedPassword);
        usuario.setPosto(posto);
        usuario.setTipo(Role.ROLE_FUNCIONARIO);
        usuario.setIsVerificado(true);
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
}
