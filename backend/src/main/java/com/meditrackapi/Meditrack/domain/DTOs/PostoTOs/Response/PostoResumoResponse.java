package com.meditrackapi.Meditrack.domain.DTOs.PostoTOs.Response;

public class PostoResumoResponse {
    private String id;
    private String nome;
    private String bairro;
    private String rua;
    private String numero;
    private String linhasOnibus;
    private String telefone;
    private String latitude;
    private String longitude;
    private Double distancia;

    public PostoResumoResponse(String id, String nome, String bairro, String rua, String numero, String linhasOnibus, String telefone, String latitude, String longitude) {
        this.id = id;
        this.nome = nome;
        this.bairro = bairro;
        this.rua = rua;
        this.numero = numero;
        this.linhasOnibus = linhasOnibus;
        this.telefone = telefone;
        this.latitude = latitude;
        this.longitude = longitude;
    }

    public PostoResumoResponse(String id, String nome, String bairro, String rua, String numero, String linhasOnibus, String telefone, String latitude, String longitude, Double distancia) {
        this.id = id;
        this.nome = nome;
        this.bairro = bairro;
        this.rua = rua;
        this.numero = numero;
        this.linhasOnibus = linhasOnibus;
        this.telefone = telefone;
        this.latitude = latitude;
        this.longitude = longitude;
        this.distancia = distancia;
    }

    public String getId() {
        return id;
    }

    public String getNome() {
        return nome;
    }

    public String getBairro() {
        return bairro;
    }

    public String getRua() {
        return rua;
    }

    public String getNumero() {
        return numero;
    }

    public String getLinhasOnibus() {
        return linhasOnibus;
    }

    public String getTelefone() {
        return telefone;
    }
    
    public String getLatitude() {
        return latitude;
    }
    
    public String getLongitude() {
        return longitude;
    }
    
    public Double getDistancia() {
        return distancia;
    }
}