package com.meditrackapi.Meditrack.api.Controller;

import com.meditrackapi.Meditrack.domain.DTOs.MedicamentoTOs.Response.MedicamentoCard;
import com.meditrackapi.Meditrack.domain.Interfaces.IMedicamentoService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;

@RestController
@RequestMapping("/api/funcionario")
public class FuncionarioController {
    private final IMedicamentoService _medicamentoService;
    public FuncionarioController(IMedicamentoService medicamentoService){
        _medicamentoService = medicamentoService;
    }

    @PostMapping(value = "/atualizar-estoque", consumes = {"multipart/form-data"})
    public ResponseEntity<Integer> atualizarEstoque(@RequestPart("file") MultipartFile file) throws IOException {
        return ResponseEntity.ok(_medicamentoService.AtualizarEstoque(file));
    }

    @GetMapping("/listar-meds")
    public ResponseEntity<List<MedicamentoCard>> listarMedicamentosDoPosto(){
        return ResponseEntity.ok(_medicamentoService.listarMedicamentosPorPosto());
    }
}
