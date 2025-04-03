package com.meditrackapi.Meditrack.domain.DTOs.MedicamentoTOs.Response;

import com.meditrackapi.Meditrack.domain.DTOs.PostoTOs.Response.ListaPostosResponse;

import java.util.Date;
import java.util.List;

public record MedicamentoResponse(
        int codigo,
        String lote,
        String nomeMedicamento,
        String tipoMedicamento,
        Date vencimento,
        boolean necessitaReceita,
        List<ListaPostosResponse> postos
) {
}
