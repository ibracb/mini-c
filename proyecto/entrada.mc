prueba() {
  const int cero = 0, uno = 1;
  var int x, y, contador;

  print ("--- INICIO DEL PROGRAMA ---\n");

  x = 10;
  y =(x ? 5 : 4);
  contador = x + y - 3;



  print ("Cuenta regresiva:\n");
  while (contador) {
    print ("contador =", contador, "\n");
    contador = contador - 1;
  }
  print ("Introduce un valor para x:\n");
  read(x);
  print ("Valor leído: ", x, "\n");

  print ("--- FIN DEL PROGRAMA ---\n");
}


