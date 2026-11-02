<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Abastecimento extends Model
{
    protected $table = 'abastecimentos';

    protected $primaryKey = 'id_abastecimento';

    public $timestamps = false;

    protected $fillable = [
        'id_veiculo',
        'data_abastecimento',
        'tipo_combustivel',
        'litros',
        'valor_litro',
        'quilometragem',
    ];

    protected function casts(): array
    {
        return [
            'data_abastecimento' => 'date',
            'litros' => 'decimal:2',
            'valor_litro' => 'decimal:2',
            'valor_total' => 'decimal:2',
            'quilometragem' => 'integer',
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
}
