@extends('layouts.app')
@section('titulo', 'Editar veículo')

@section('content')
<h1 class="h3 mb-3">Editar veículo</h1>
<form method="POST" action="{{ route('veiculos.update', $veiculo) }}">
  @csrf
  @method('PUT')
  @include('veiculos._form')
</form>
@endsection