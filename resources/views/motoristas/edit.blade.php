@extends('layouts.app')
@section('titulo', 'Editar motorista')

@section('content')
<h1 class="h3 mb-3">Editar motorista</h1>
<form method="POST" action="{{ route('motoristas.update', $motorista) }}">
  @csrf
  @method('PUT')
  @include('motoristas._form')
</form>
@endsection