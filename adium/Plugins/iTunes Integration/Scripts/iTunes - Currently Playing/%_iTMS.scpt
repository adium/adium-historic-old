FasdUAS 1.101.10   ��   ��    k             l     �� ��      Author: Gregory Barchard       	  l     �� 
��   
   Date: June 6, 2004    	     l     �� ��    R L Created by referencing: http://nslog.com/archives/2003/04/29/itms_links.php         l     �� ��    Z T and http://www.macosxhints.com/article.php?story=20031009010901765&query=music+link         l     �� ��    g a and http://maccentral.macworld.com/features/applescriptprimer33/index.php?redirect=1086544628000         i         I      �������� 0 keyword  ��  ��    L        m         %_itms         l     ������  ��        i        I      �������� 	0 title  ��  ��    L          m      ! !  iTunes Music Store Link      " # " l     ������  ��   #  $ % $ i     & ' & I      �������� 0 
substitute  ��  ��   ' O     � ( ) ( Z    � * +���� * ?    , - , l    .�� . I   �� /��
�� .corecnte****       **** / l    0�� 0 6    1 2 1 2   ��
�� 
pcap 2 l    3�� 3 =    4 5 4 1   	 ��
�� 
pnam 5 m     6 6  iTunes   ��  ��  ��  ��   - m    ����   + k    � 7 7  8 9 8 O    � : ; : Z    � < =�� > < >   " ? @ ? 1     ��
�� 
pPlS @ m     !��
�� ePlSkPSS = k   % � A A  B C B r   % , D E D n   % * F G F 1   ( *��
�� 
pnam G 1   % (��
�� 
pTrk E o      ���� 0 	trackname 	trackName C  H I H r   - 4 J K J n   - 2 L M L 1   0 2��
�� 
pArt M 1   - 0��
�� 
pTrk K o      ���� 0 
artistname 
artistName I  N O N r   5 A P Q P n  5 ? R S R I   6 ?�� T���� 0 string_parser   T  U�� U n   6 ; V W V 1   9 ;��
�� 
pAlb W 1   6 9��
�� 
pTrk��  ��   S  f   5 6 Q o      ���� 0 	albumname 	albumName O  X Y X r   B N Z [ Z n  B L \ ] \ I   C L�� ^���� 0 string_parser   ^  _�� _ n   C H ` a ` 1   F H��
�� 
pCmp a 1   C F��
�� 
pTrk��  ��   ]  f   B C [ o      ���� 0 composername composerName Y  b c b r   O � d e d l  O � f�� f b   O � g h g b   O � i j i b   O � k l k b   O � m n m b   O � o p o b   O � q r q b   O ~ s t s b   O z u v u b   O v w x w b   O t y z y b   O p { | { b   O l } ~ } b   O e  �  b   O a � � � b   O ] � � � b   O V � � � b   O R � � � m   O P � �  <HTML><A HREF="    � m   P Q � � O Iitms://phobos.apple.com/WebObjects/MZSearch.woa/wa/advancedSearchResults?    � m   R U � �  	songTerm=    � n  V \ � � � I   W \�� ����� 0 string_parser   �  ��� � o   W X���� 0 	trackname 	trackName��  ��   �  f   V W � m   ] ` � �  &    � m   a d � �  artistTerm=    ~ n  e k � � � I   f k�� ����� 0 string_parser   �  ��� � o   f g���� 0 
artistname 
artistName��  ��   �  f   e f | m   l o � �  &    z m   p s � �  
albumTerm=    x o   t u���� 0 	albumname 	albumName v m   v y � �  &    t m   z } � �  composerTerm=    r o   ~ ���� 0 composername composerName p m   � � � �  ">    n o   � ����� 0 
artistname 
artistName l m   � � � � 	  -     j o   � ����� 0 	trackname 	trackName h m   � � � �  </A></HTML>   ��   e o      ���� 0 itmslink iTMSLink c  ��� � L   � � � � o   � ����� 0 itmslink iTMSLink��  ��   > L   � � � � m   � � � �       ; m     � ��null     � ��  ^
iTunes.app��0� �0�L��� 7���`   � S�D   )       (�K� ��Ӏ Thook  alis    L  Macintosh HD               ����H+    ^
iTunes.app                                                      �໳T�        ����  	                Applications    ��      ����      ^  $Macintosh HD:Applications:iTunes.app   
 i T u n e s . a p p    M a c i n t o s h   H D  Applications/iTunes.app   / ��   9  ��� � l   � ��� ���   �  else
			return "Off"   ��  ��  ��   ) m      � ��null      � ��  
System Events.app�L��� 7���     S�    )       (�K� ���  Tsevs   alis    �  Macintosh HD               ����H+    
System Events.app                                                Z�����        ����  	                CoreServices    ��      ��<      
  
  
  :Macintosh HD:System:Library:CoreServices:System Events.app  $  S y s t e m   E v e n t s . a p p    M a c i n t o s h   H D  -System/Library/CoreServices/System Events.app   / ��   %  � � � l     ������  ��   �  � � � i     � � � I      �� ����� 0 string_parser   �  ��� � o      ���� 0 txt  ��  ��   � k     2 � �  � � � r      � � � c      � � � o     ���� 0 txt   � m    ��
�� 
TEXT � o      ���� 0 thetext theText �  � � � r    	 � � � m     � �  +    � o      ���� 0 replacestring ReplaceString �  � � � l  
 
������  ��   �  � � � r   
  � � � n  
  � � � 1    ��
�� 
txdl � 1   
 ��
�� 
ascr � o      ���� 0 	olddelims 	OldDelims �  � � � r     � � � m     � �       � n      � � � 1    ��
�� 
txdl � 1    ��
�� 
ascr �  � � � r     � � � n     � � � 2   ��
�� 
citm � o    ���� 0 thetext theText � o      ���� 0 newtext newText �  � � � r    ! � � � o    ���� 0 replacestring ReplaceString � n      � � � 1     ��
�� 
txdl � 1    ��
�� 
ascr �  � � � r   " ' � � � c   " % � � � o   " #���� 0 newtext newText � m   # $��
�� 
ctxt � o      ���� 0 parsedstring parsedString �  � � � r   ( - � � � o   ( )���� 0 	olddelims 	OldDelims � n      � � � 1   * ,��
�� 
txdl � 1   ) *��
�� 
ascr �  � � � o   . /���� 0 parsedstring parsedString �  ��� � L   0 2 � � l  0 1 ��� � o   0 1���� 0 parsedstring parsedString��  ��   �  ��� � l     ������  ��  ��       �� � � � � ���   � ���������� 0 keyword  �� 	0 title  �� 0 
substitute  �� 0 string_parser   � �� ���� � ����� 0 keyword  ��  ��   �   �  �� � � �� ���� � ����� 	0 title  ��  ��   �   �  !�� � � �� '���� � ����� 0 
substitute  ��  ��   � ������������ 0 	trackname 	trackName�� 0 
artistname 
artistName�� 0 	albumname 	albumName�� 0 composername composerName�� 0 itmslink iTMSLink �  ��� ��� 6� ��~�}�|�{�z�y�x � � � � � � � � � � � � �
�� 
pcap �  
�� 
pnam
� .corecnte****       ****
�~ 
pPlS
�} ePlSkPSS
�| 
pTrk
�{ 
pArt
�z 
pAlb�y 0 string_parser  
�x 
pCmp�� �� �*�-�[�,\Z�81j j �� �*�,� u*�,�,E�O*�,�,E�O)*�,�,k+ E�O)*�,�,k+ E�O��%a %)�k+ %a %a %)�k+ %a %a %�%a %a %�%a %�%a %�%a %E�O�Y a UOPY hU � �w ��v�u � ��t�w 0 string_parser  �v �s ��s  �  �r�r 0 txt  �u   � �q�p�o�n�m�l�q 0 txt  �p 0 thetext theText�o 0 replacestring ReplaceString�n 0 	olddelims 	OldDelims�m 0 newtext newText�l 0 parsedstring parsedString � �k ��j�i ��h�g
�k 
TEXT
�j 
ascr
�i 
txdl
�h 
citm
�g 
ctxt�t 3��&E�O�E�O��,E�O���,FO��-E�O���,FO��&E�O���,FO�O� ascr  ��ޭ