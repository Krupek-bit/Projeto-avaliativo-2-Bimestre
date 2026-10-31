<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Hodometro extends Model
{
    protected $table = 'hodometros';

    protected $primaryKey = 'id_hodometro';

    public $timestamps = false;

    protected $fillable = [
        'id_veiculo',
        'data_registro',
        'quilometragem',
        'observacao',
    ];

    protected function casts(): array
    {
        return [
            'data_registro' => 'date',
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
