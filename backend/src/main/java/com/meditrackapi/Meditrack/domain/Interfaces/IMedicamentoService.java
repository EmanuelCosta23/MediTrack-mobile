package com.meditrackapi.Meditrack.domain.Interfaces;

import com.meditrackapi.Meditrack.domain.DTOs.MedicamentoTOs.Response.ListaMedsResponse;
import com.meditrackapi.Meditrack.domain.DTOs.MedicamentoTOs.Response.MedicamentoCard;
import com.meditrackapi.Meditrack.domain.DTOs.MedicamentoTOs.Response.MedicamentoResponse;
import com.meditrackapi.Meditrack.domain.Entities.Medicamento;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;
import java.util.Set;

public interface IMedicamentoService {
    List<ListaMedsResponse> SearchByName(String nome);
    MedicamentoResponse SearchById(String medicamentoId);
    Integer InserirCargaMedicamentos(MultipartFile file) throws IOException;
    Integer AtualizarEstoque(MultipartFile file) throws IOException;
    List<MedicamentoCard> listarMedicamentosPorPosto();
    void favoritarMedicamento(String medicamentoId);
    List<MedicamentoCard> listarMedicamentosFavoritos();
}
