package com.meditrackapi.Meditrack.domain.DTOs.PostoTOs.Response;

import com.meditrackapi.Meditrack.domain.DTOs.MedicamentoTOs.Response.MedicamentoCard;
import java.util.List;

public class PostoComMedicamentosResponse {
    private String id;
    private String nome;
    private List<MedicamentoCard> medicamentos;

    public PostoComMedicamentosResponse(String id, String nome) {
        this.id = id;
        this.nome = nome;
    }

    public String getId() {
        return id;
    }

    public String getNome() {
        return nome;
    }

    public List<MedicamentoCard> getMedicamentos() {
        return medicamentos;
    }

    public void setMedicamentos(List<MedicamentoCard> medicamentos) {
        this.medicamentos = medicamentos;
    }
}