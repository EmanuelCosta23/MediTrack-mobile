package com.meditrackapi.Meditrack.api.Controller;

import com.meditrackapi.Meditrack.domain.DTOs.MedicamentoTOs.Response.ListaMedsResponse;
import com.meditrackapi.Meditrack.domain.DTOs.MedicamentoTOs.Response.MedicamentoCard;
import com.meditrackapi.Meditrack.domain.DTOs.MedicamentoTOs.Response.MedicamentoResponse;
import com.meditrackapi.Meditrack.domain.Entities.Medicamento;
import com.meditrackapi.Meditrack.domain.Interfaces.IMedicamentoService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/medicamento")
public class MedicamentoController {

    private final IMedicamentoService _medicamentoService;
    public MedicamentoController(IMedicamentoService medicamentoService){
        _medicamentoService = medicamentoService;
    }

    @GetMapping("/pesquisar/{nome}")
    public ResponseEntity<List<ListaMedsResponse>> buscarMedicamentosPorNome(@PathVariable String nome){
        List<ListaMedsResponse> response = _medicamentoService.SearchByName(nome);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/{id}")
    public ResponseEntity<MedicamentoResponse> buscarMedicamentoPorId(@PathVariable String id){
        MedicamentoResponse response = _medicamentoService.SearchById(id);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/favoritar/{medicamentoId}")
    public ResponseEntity<String> favoritarMedicamento(@PathVariable String medicamentoId){
        _medicamentoService.favoritarMedicamento(medicamentoId);
        return ResponseEntity.ok("Medicamento salvo com sucesso.");
    }

    @GetMapping("/favoritos")
    public ResponseEntity<List<MedicamentoCard>> listarFavoritos(){
        return ResponseEntity.ok(_medicamentoService.listarMedicamentosFavoritos());
    }

}
