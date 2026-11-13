<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Veiculo extends Model
{
    protected $table = 'gabriel_trabalho_bd.veiculos';

    protected $primaryKey = 'id_veiculo';

    public $timestamps = false;

    protected $fillable = [
        'placa',
        'marca',
        'modelo',
        'tipo',
        'capacidade',
        'status',
        'ano',
        'quilometragem_atual',
    ];

    protected function casts(): array
    {
        return [
            'capacidade' => 'decimal:2',
            'quilometragem_atual' => 'integer',
            'ano' => 'integer',
        ];
    }

    public function viagens(): HasMany
    {
        return $this->hasMany(
            Viagem::class,
            'id_veiculo',
            'id_veiculo'
        );
    }

    public function abastecimentos(): HasMany
    {
        return $this->hasMany(
            Abastecimento::class,
            'id_veiculo',
            'id_veiculo'
        );
    }

    public function manutencoes(): HasMany
    {
        return $this->hasMany(
            Manutencao::class,
            'id_veiculo',
            'id_veiculo'
        );
    }

    public function despesas(): HasMany
    {
        return $this->hasMany(
            Despesa::class,
            'id_veiculo',
            'id_veiculo'
        );
    }

    public function hodometros(): HasMany
    {
        return $this->hasMany(
            Hodometro::class,
            'id_veiculo',
            'id_veiculo'
        );
    }

    public function historicoStatus(): HasMany
    {
        return $this->hasMany(
            HistoricoStatusVeiculo::class,
            'id_veiculo',
            'id_veiculo'
        );
    }
}
