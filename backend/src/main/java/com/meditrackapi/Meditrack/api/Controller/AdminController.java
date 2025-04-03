package com.meditrackapi.Meditrack.api.Controller;

import com.meditrackapi.Meditrack.domain.DTOs.PostoTOs.Response.PostoDetalhadoResponse;
import com.meditrackapi.Meditrack.domain.DTOs.UsuarioTOs.FuncionarioSignupRequest;
import com.meditrackapi.Meditrack.domain.DTOs.UsuarioTOs.UsuarioResponseDTO;
import com.meditrackapi.Meditrack.domain.Interfaces.IAdminService;
import com.meditrackapi.Meditrack.domain.Interfaces.IMedicamentoService;
import com.meditrackapi.Meditrack.domain.Interfaces.IPostoService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOError;
import java.io.IOException;
import java.util.List;

@RestController
@RequestMapping("/api/admin")
public class AdminController {
    private final IMedicamentoService _medicamentoService;
    private final IAdminService _adminService;
    public AdminController(IMedicamentoService medicamentoService, IAdminService adminService){
        _medicamentoService = medicamentoService;
        _adminService = adminService;
    }

    @PostMapping(value = "/upload-meds", consumes = {"multipart/form-data"})
    public ResponseEntity<Integer> uploadMedicamentos(@RequestPart("file") MultipartFile file) throws IOException {
        return ResponseEntity.ok(_medicamentoService.InserirCargaMedicamentos(file));
    }

    @PostMapping("/cadastrar-funcionario")
    public ResponseEntity<UsuarioResponseDTO> cadastrarFuncionario(@RequestBody @Valid FuncionarioSignupRequest novoFuncionario){
        return ResponseEntity.ok(_adminService.cadastrarFuncionario(novoFuncionario));
    }
}
