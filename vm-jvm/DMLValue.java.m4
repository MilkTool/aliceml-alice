/*
 * $Date$
 * $Revision$
 * $Author$
 */

package de.uni_sb.ps.dml.runtime;

/** Darstellung von Werten in DML. Klassen, die Werte in DML repr�sentieren,
 *  m�ssen dieses Interface implementieren.
*/
public interface DMLValue extends java.io.Serializable {
    /** Funktionale Werte und Konstruktoren k�nnen mit dieser Methode
     *  appliziert werden. Andere Werte erzeugen Laufzeitfehler.
     *  @param val der formale Parameter der Funktion/des Konstruktors
     *  @return DMLValue das Ergebnis der Applikation
     */
    public DMLValue apply(DMLValue val) throws java.rmi.RemoteException;

}
