<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Motorista extends Model
{
    protected $table = 'gabriel_trabalho_bd.motoristas';

    protected $primaryKey = 'id_motorista';

    public $timestamps = false;

    protected $fillable = [
        'nome',
        'cnh',
        'categoria_cnh',
        'telefone',
        'data_admissao',
        'status',
        'validade_cnh',
    ];

    protected function casts(): array
    {
        return [
            'data_admissao' => 'date',
            'validade_cnh' => 'date',
        ];
    }

    public function viagens(): HasMany
    {
        return $this->hasMany(
            Viagem::class,
            'id_motorista',
            'id_motorista'
        );
    }
}
