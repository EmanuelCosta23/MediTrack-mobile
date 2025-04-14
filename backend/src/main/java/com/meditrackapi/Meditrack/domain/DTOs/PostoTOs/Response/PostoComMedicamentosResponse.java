package com.meditrackapi.Meditrack.domain.DTOs.PostoTOs.Response;

import com.meditrackapi.Meditrack.domain.DTOs.MedicamentoTOs.Response.MedicamentoCard;
import java.util.List;

public class PostoComMedicamentosResponse {
    private String id;
    private String nome;
    private String latitude;
    private String longitude;
    private List<MedicamentoCard> medicamentos;

    public PostoComMedicamentosResponse(String id, String nome) {
        this.id = id;
        this.nome = nome;
    }

    public PostoComMedicamentosResponse(String id, String nome, String latitude, String longitude) {
        this.id = id;
        this.nome = nome;
        this.latitude = latitude;
        this.longitude = longitude;
    }

    public String getId() {
        return id;
    }

    public String getNome() {
        return nome;
    }

    public String getLatitude() {
        return latitude;
    }

    public String getLongitude() {
        return longitude;
    }

    public List<MedicamentoCard> getMedicamentos() {
        return medicamentos;
    }

    public void setMedicamentos(List<MedicamentoCard> medicamentos) {
        this.medicamentos = medicamentos;
    }
}