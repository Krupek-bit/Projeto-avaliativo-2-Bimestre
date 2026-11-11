@extends('layouts.app')
@section('titulo', 'Detalhes da viagem')

@section('content')
<div class="card mb-4">
    <div class="card-body">
        <h1 class="h4">Viagem para {{ $viagem->destino }}</h1>

        <div class="row g-3 mt-2">
            <div class="col-md-4">
                <strong>Veículo:</strong> {{ $viagem->veiculo->placa ?? '-' }}
            </div>

            <div class="col-md-4">
                <strong>Motorista:</strong> {{ $viagem->motorista->nome ?? '-' }}
            </div>

            <div class="col-md-4">
                <strong>Finalidade:</strong> {{ $viagem->finalidade ?? '-' }}
            </div>

            <div class="col-md-4">
                <strong>Saída:</strong>
                {{ $viagem->data_saida?->format('d/m/Y H:i') }}
            </div>

            <div class="col-md-4">
                <strong>Retorno:</strong>
                {{ $viagem->data_retorno?->format('d/m/Y H:i') ?? 'Em andamento' }}
            </div>

            <div class="col-md-4">
                <strong>Quilometragem:</strong>
                {{ $viagem->km_inicial }} → {{ $viagem->km_final ?? '-' }}
            </div>
        </div>
    </div>
</div>

@if(!$viagem->data_retorno)
    <div class="card mb-4">
        <div class="card-body">
            <h2 class="h5">Finalizar viagem</h2>

            <form method="POST" action="{{ route('viagens.finalizar', $viagem->id_viagem) }}">
                @csrf

                <div class="mb-3">
                    <label class="form-label">Quilometragem final</label>

                    <input
                        type="number"
                        name="km_final"
                        min="0"
                        class="form-control @error('km_final') is-invalid @enderror"
                        value="{{ old('km_final') }}"
                        required
                    >

                    @error('km_final')
                        <div class="invalid-feedback">{{ $message }}</div>
                    @enderror
                </div>

                @error('viagem')
                    <div class="alert alert-danger">{{ $message }}</div>
                @enderror

                <button type="submit" class="btn btn-success">
                    Finalizar viagem
                </button>
            </form>
        </div>
    </div>
@endif

<a href="{{ route('viagens.index') }}" class="btn btn-secondary">
    Voltar
</a>
@endsection
