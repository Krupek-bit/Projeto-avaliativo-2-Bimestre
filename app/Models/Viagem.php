<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Viagem extends Model
{
    protected $table = 'viagens';

    protected $primaryKey = 'id_viagem';

    public $timestamps = false;

    protected $fillable = [
        'id_veiculo',
        'id_motorista',
        'data_saida',
        'data_retorno',
        'km_inicial',
        'km_final',
        'destino',
        'finalidade',
    ];

    protected function casts(): array
    {
        return [
            'data_saida' => 'datetime',
            'data_retorno' => 'datetime',
            'km_inicial' => 'integer',
            'km_final' => 'integer',
        ];
    }

    public function veiculo(): BelongsTo
    {
        return $this->belongsTo(
            Veiculo::class,
            'id_veiculo',
            'id_veiculo'
        );
    }

    public function motorista(): BelongsTo
    {
        return $this->belongsTo(
            Motorista::class,
            'id_motorista',
            'id_motorista'
        );
    }
}
